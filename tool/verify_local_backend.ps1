[CmdletBinding()]
param(
  [string]$SupabaseCli = '',
  [switch]$SkipRecovery,
  [switch]$SkipInvitationMutation,
  [switch]$KeepMutatedState
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:AssertionCount = 0
$script:ProjectRoot = Split-Path -Parent $PSScriptRoot

function Resolve-SupabaseCli {
  if (-not [string]::IsNullOrWhiteSpace($SupabaseCli)) {
    if (-not (Test-Path -LiteralPath $SupabaseCli)) {
      throw "Supabase CLI not found: $SupabaseCli"
    }
    return (Resolve-Path -LiteralPath $SupabaseCli).Path
  }

  $command = Get-Command supabase -ErrorAction SilentlyContinue
  if ($null -ne $command) {
    return $command.Source
  }

  $outputsRoot = Split-Path -Parent $script:ProjectRoot
  $workspaceRoot = Split-Path -Parent $outputsRoot
  $candidate = Join-Path $workspaceRoot 'work'
  $candidate = Join-Path $candidate 'toolchains'
  $candidate = Join-Path $candidate 'supabase'
  $candidate = Join-Path $candidate 'supabase.exe'
  if (Test-Path -LiteralPath $candidate) {
    return (Resolve-Path -LiteralPath $candidate).Path
  }

  throw 'Supabase CLI is not on PATH and the workspace-local CLI was not found.'
}

$script:SupabaseExe = Resolve-SupabaseCli

function Get-LocalStatus {
  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = 'SilentlyContinue'
  $raw = (& $script:SupabaseExe status -o json 2>$null) -join "`n"
  $exitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousPreference

  if ($exitCode -ne 0) {
    throw "supabase status failed with exit code $exitCode."
  }

  try {
    return $raw | ConvertFrom-Json
  }
  catch {
    throw 'Supabase status did not return valid JSON.'
  }
}

function Convert-CcBody {
  param([string]$Raw)

  if ([string]::IsNullOrWhiteSpace($Raw)) {
    return $null
  }
  try {
    return $Raw | ConvertFrom-Json
  }
  catch {
    return $Raw
  }
}

function Invoke-CcHttp {
  param(
    [Parameter(Mandatory = $true)][string]$Method,
    [Parameter(Mandatory = $true)][string]$Uri,
    [hashtable]$Headers = @{},
    $Body = $null
  )

  $request = @{
    Method = $Method
    Uri = $Uri
    Headers = $Headers
    UseBasicParsing = $true
    ErrorAction = 'Stop'
  }
  if ($null -ne $Body) {
    $request.ContentType = 'application/json'
    $request.Body = $Body | ConvertTo-Json -Depth 20 -Compress
  }

  try {
    $response = Invoke-WebRequest @request
    return [pscustomobject]@{
      Ok = $true
      Status = [int]$response.StatusCode
      Body = Convert-CcBody $response.Content
    }
  }
  catch {
    $failure = $_
    $status = 0
    if ($null -ne $failure.Exception.Response) {
      try {
        $status = [int]$failure.Exception.Response.StatusCode
      }
      catch {}
    }

    $raw = $failure.ErrorDetails.Message
    if ([string]::IsNullOrWhiteSpace($raw) -and
        $null -ne $failure.Exception.Response) {
      try {
        $reader = New-Object System.IO.StreamReader(
          $failure.Exception.Response.GetResponseStream()
        )
        $raw = $reader.ReadToEnd()
        $reader.Dispose()
      }
      catch {}
    }

    return [pscustomobject]@{
      Ok = $false
      Status = $status
      Body = Convert-CcBody $raw
    }
  }
}

function Assert-Cc {
  param([bool]$Condition, [string]$Label)

  if (-not $Condition) {
    throw "FAIL: $Label"
  }
  $script:AssertionCount += 1
  Write-Host "PASS: $Label" -ForegroundColor Green
}

function Assert-CcStatus {
  param($Response, [int[]]$Expected, [string]$Label)

  if ($Expected -notcontains [int]$Response.Status) {
    $detail = $Response.Body | ConvertTo-Json -Depth 20 -Compress
    throw "FAIL: $Label; HTTP $($Response.Status); $detail"
  }
  $script:AssertionCount += 1
  Write-Host "PASS: $Label (HTTP $($Response.Status))" -ForegroundColor Green
}

function Assert-CcSet {
  param($Actual, $Expected, [string]$Label)

  $actualValues = @($Actual | Sort-Object)
  $expectedValues = @($Expected | Sort-Object)
  $difference = @(Compare-Object $expectedValues $actualValues)
  Assert-Cc ($difference.Count -eq 0) $Label
}

function New-CcSession {
  param([string]$Email, [string]$PasswordValue = $script:Password)

  $response = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/auth/v1/token?grant_type=password" `
    -Headers @{ apikey = $script:PublicKey } `
    -Body @{ email = $Email; password = $PasswordValue }

  Assert-CcStatus $response @(200) "login $Email"
  Assert-Cc `
    (-not [string]::IsNullOrWhiteSpace($response.Body.access_token)) `
    "access token returned for $Email"
  Assert-Cc `
    (-not [string]::IsNullOrWhiteSpace($response.Body.refresh_token)) `
    "refresh token returned for $Email"
  return $response.Body
}

function Get-CcContext {
  param($Session)

  $response = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/rest/v1/rpc/get_my_identity_context" `
    -Headers @{
      apikey = $script:PublicKey
      Authorization = "Bearer $($Session.access_token)"
    } `
    -Body @{}

  Assert-CcStatus $response @(200) 'get_my_identity_context'
  return $response.Body
}

function Invoke-CcRpc {
  param($Session, [string]$Name, [hashtable]$Parameters)

  return Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/rest/v1/rpc/$Name" `
    -Headers @{
      apikey = $script:PublicKey
      Authorization = "Bearer $($Session.access_token)"
    } `
    -Body $Parameters
}

function ConvertTo-CcBase64Url {
  param([byte[]]$Bytes)

  return [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function New-CcExpiredToken {
  param([string]$Secret, [string]$UserId, [string]$Email)

  $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $header = @{ alg = 'HS256'; typ = 'JWT' } | ConvertTo-Json -Compress
  $payload = @{
    aud = 'authenticated'
    email = $Email
    exp = $now - 60
    iat = $now - 120
    iss = 'supabase-demo'
    role = 'authenticated'
    sub = $UserId
  } | ConvertTo-Json -Compress

  $encoding = New-Object System.Text.UTF8Encoding($false)
  $encodedHeader = ConvertTo-CcBase64Url $encoding.GetBytes($header)
  $encodedPayload = ConvertTo-CcBase64Url $encoding.GetBytes($payload)
  $unsigned = "$encodedHeader.$encodedPayload"
  $hmac = New-Object System.Security.Cryptography.HMACSHA256
  try {
    $hmac.Key = $encoding.GetBytes($Secret)
    $signature = $hmac.ComputeHash($encoding.GetBytes($unsigned))
  }
  finally {
    $hmac.Dispose()
  }
  return "$unsigned.$(ConvertTo-CcBase64Url $signature)"
}

function New-CcRecoveryToken {
  param([string]$Secret, [string]$UserId, [string]$Email)

  $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $header = @{ alg = 'HS256'; typ = 'JWT' } | ConvertTo-Json -Compress
  $payload = @{
    aal = 'aal1'
    amr = @(@{ method = 'otp'; timestamp = $now })
    aud = 'authenticated'
    email = $Email
    exp = $now + 600
    iat = $now
    is_anonymous = $false
    iss = 'supabase-demo'
    role = 'authenticated'
    session_id = [guid]::NewGuid().ToString()
    sub = $UserId
  } | ConvertTo-Json -Depth 10 -Compress

  $encoding = New-Object System.Text.UTF8Encoding($false)
  $encodedHeader = ConvertTo-CcBase64Url $encoding.GetBytes($header)
  $encodedPayload = ConvertTo-CcBase64Url $encoding.GetBytes($payload)
  $unsigned = "$encodedHeader.$encodedPayload"
  $hmac = New-Object System.Security.Cryptography.HMACSHA256
  try {
    $hmac.Key = $encoding.GetBytes($Secret)
    $signature = $hmac.ComputeHash($encoding.GetBytes($unsigned))
  }
  finally {
    $hmac.Dispose()
  }
  return "$unsigned.$(ConvertTo-CcBase64Url $signature)"
}

function Reset-CcDatabase {
  Write-Host 'Restoring deterministic seed state...'
  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  & $script:SupabaseExe db reset --local
  $exitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousPreference
  if ($exitCode -ne 0) {
    throw "supabase db reset failed with exit code $exitCode."
  }
}

Push-Location -LiteralPath $script:ProjectRoot
$suiteError = $null
$cleanupError = $null
try {
  $local = Get-LocalStatus
  $script:ApiUrl = $local.API_URL
  $publishableKey = $local.PSObject.Properties['PUBLISHABLE_KEY']
  if (
    $null -ne $publishableKey -and
    -not [string]::IsNullOrWhiteSpace([string]$publishableKey.Value)
  ) {
    $script:PublicKey = [string]$publishableKey.Value
  }
  else {
    $script:PublicKey = $local.ANON_KEY
  }
  $script:ServiceRoleKey = $local.SERVICE_ROLE_KEY
  $script:JwtSecret = $local.JWT_SECRET
  $script:MailUrl = $local.MAILPIT_URL
  $script:Password = 'CampusConnectDevOnly!'

  Assert-Cc (-not [string]::IsNullOrWhiteSpace($script:ApiUrl)) 'local API URL available'
  Assert-Cc (-not [string]::IsNullOrWhiteSpace($script:PublicKey)) 'local public client key available'
  Assert-Cc (-not [string]::IsNullOrWhiteSpace($script:ServiceRoleKey)) 'local service key available to test harness'

  $wrongPassword = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/auth/v1/token?grant_type=password" `
    -Headers @{ apikey = $script:PublicKey } `
    -Body @{
      email = 'student.active@campusconnect.local.invalid'
      password = 'DefinitelyWrong!'
    }
  Assert-CcStatus $wrongPassword @(400) 'wrong password rejected'
  Assert-Cc `
    ($wrongPassword.Body.error_code -eq 'invalid_credentials') `
    'wrong password uses generic invalid credentials response'

  $unknownUser = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/auth/v1/token?grant_type=password" `
    -Headers @{ apikey = $script:PublicKey } `
    -Body @{
      email = 'unknown@campusconnect.local.invalid'
      password = $script:Password
    }
  Assert-CcStatus $unknownUser @(400) 'unknown user rejected'

  $anonymousRpc = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/rest/v1/rpc/get_my_identity_context" `
    -Headers @{ apikey = $script:PublicKey } `
    -Body @{}
  Assert-CcStatus $anonymousRpc @(401, 403) 'identity RPC rejects anonymous caller'

  $expiredToken = New-CcExpiredToken `
    -Secret $script:JwtSecret `
    -UserId '10000000-0000-4000-8000-000000000001' `
    -Email 'student.active@campusconnect.local.invalid'
  $expiredSession = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/rest/v1/rpc/get_my_identity_context" `
    -Headers @{
      apikey = $script:PublicKey
      Authorization = "Bearer $expiredToken"
    } `
    -Body @{}
  Assert-CcStatus $expiredSession @(401) 'expired access token rejected'

  $recoveryToken = New-CcRecoveryToken `
    -Secret $script:JwtSecret `
    -UserId '10000000-0000-4000-8000-000000000001' `
    -Email 'student.active@campusconnect.local.invalid'
  $recoveryRpc = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/rest/v1/rpc/get_my_identity_context" `
    -Headers @{
      apikey = $script:PublicKey
      Authorization = "Bearer $recoveryToken"
    } `
    -Body @{}
  Assert-CcStatus $recoveryRpc @(403) 'OTP recovery token cannot call identity RPC'
  Assert-Cc ($recoveryRpc.Body.code -eq '42501') 'OTP recovery RPC denial SQLSTATE'

  $recoveryProfile = Invoke-CcHttp `
    -Method GET `
    -Uri "$($script:ApiUrl)/rest/v1/profiles?select=user_id&user_id=eq.10000000-0000-4000-8000-000000000001" `
    -Headers @{
      apikey = $script:PublicKey
      Authorization = "Bearer $recoveryToken"
    }
  Assert-CcStatus $recoveryProfile @(200) 'OTP recovery profile RLS request'
  Assert-Cc (@($recoveryProfile.Body).Count -eq 0) 'OTP recovery token cannot read profile'

  $cases = @(
    [pscustomobject]@{
      Email = 'student.active@campusconnect.local.invalid'
      UserId = '10000000-0000-4000-8000-000000000001'
      MembershipId = '30000000-0000-4000-8000-000000000001'
      MembershipStatus = 'active'
      InstitutionId = '20000000-0000-4000-8000-000000000001'
      InstitutionActive = $true
      ProfileCompleted = $true
      Roles = @('student')
    },
    [pscustomobject]@{
      Email = 'faculty.active@campusconnect.local.invalid'
      UserId = '10000000-0000-4000-8000-000000000002'
      MembershipId = '30000000-0000-4000-8000-000000000002'
      MembershipStatus = 'active'
      InstitutionId = '20000000-0000-4000-8000-000000000001'
      InstitutionActive = $true
      ProfileCompleted = $true
      Roles = @('faculty')
    },
    [pscustomobject]@{
      Email = 'member.multi-role@campusconnect.local.invalid'
      UserId = '10000000-0000-4000-8000-000000000003'
      MembershipId = '30000000-0000-4000-8000-000000000003'
      MembershipStatus = 'active'
      InstitutionId = '20000000-0000-4000-8000-000000000001'
      InstitutionActive = $true
      ProfileCompleted = $true
      Roles = @('faculty', 'student')
    },
    [pscustomobject]@{
      Email = 'member.invited@campusconnect.local.invalid'
      UserId = '10000000-0000-4000-8000-000000000004'
      MembershipId = '30000000-0000-4000-8000-000000000004'
      MembershipStatus = 'invited'
      InstitutionId = '20000000-0000-4000-8000-000000000001'
      InstitutionActive = $true
      ProfileCompleted = $false
      Roles = @('student')
    },
    [pscustomobject]@{
      Email = 'member.expired-invite@campusconnect.local.invalid'
      UserId = '10000000-0000-4000-8000-000000000005'
      MembershipId = '30000000-0000-4000-8000-000000000005'
      MembershipStatus = 'invited'
      InstitutionId = '20000000-0000-4000-8000-000000000001'
      InstitutionActive = $true
      ProfileCompleted = $false
      Roles = @('student')
    },
    [pscustomobject]@{
      Email = 'member.suspended@campusconnect.local.invalid'
      UserId = '10000000-0000-4000-8000-000000000006'
      MembershipId = '30000000-0000-4000-8000-000000000006'
      MembershipStatus = 'suspended'
      InstitutionId = '20000000-0000-4000-8000-000000000001'
      InstitutionActive = $true
      ProfileCompleted = $true
      Roles = @('student')
    },
    [pscustomobject]@{
      Email = 'member.inactive-campus@campusconnect.local.invalid'
      UserId = '10000000-0000-4000-8000-000000000007'
      MembershipId = '30000000-0000-4000-8000-000000000007'
      MembershipStatus = 'active'
      InstitutionId = '20000000-0000-4000-8000-000000000002'
      InstitutionActive = $false
      ProfileCompleted = $true
      Roles = @('student')
    }
  )

  $sessions = @{}
  $contexts = @{}
  foreach ($case in $cases) {
    $session = New-CcSession $case.Email
    $context = Get-CcContext $session
    $membership = @($context.memberships)[0]
    $sessions[$case.Email] = $session
    $contexts[$case.Email] = $context

    Assert-Cc ($session.user.id -eq $case.UserId) "$($case.Email): Auth user ID"
    Assert-Cc ($context.user_id -eq $case.UserId) "$($case.Email): context user ID"
    Assert-Cc (@($context.memberships).Count -eq 1) "$($case.Email): one membership"
    Assert-Cc ($membership.id -eq $case.MembershipId) "$($case.Email): membership ID"
    Assert-Cc ($membership.status -eq $case.MembershipStatus) "$($case.Email): membership status"
    Assert-Cc ($membership.institution_id -eq $case.InstitutionId) "$($case.Email): institution ID"
    Assert-Cc `
      ([bool]$membership.institution_active -eq $case.InstitutionActive) `
      "$($case.Email): institution active flag"
    Assert-Cc `
      (($null -ne $context.profile.profile_completed_at) -eq $case.ProfileCompleted) `
      "$($case.Email): profile completion"

    $actualRoles = @(@($membership.roles) | ForEach-Object { $_.key })
    Assert-CcSet $actualRoles $case.Roles "$($case.Email): exact roles"
    foreach ($role in @($membership.roles)) {
      if ($role.key -eq 'student') {
        $expectedPermissions = @('attendance_read_own')
      }
      elseif ($role.key -eq 'faculty') {
        $expectedPermissions = @('attendance_record', 'roster_read')
      }
      else {
        $expectedPermissions = @()
      }
      Assert-CcSet `
        @($role.permissions) `
        $expectedPermissions `
        "$($case.Email): exact $($role.key) permissions"
    }
  }

  $student = $sessions['student.active@campusconnect.local.invalid']
  $crossTenant = Invoke-CcHttp `
    -Method GET `
    -Uri "$($script:ApiUrl)/rest/v1/institutions?select=id&id=eq.20000000-0000-4000-8000-000000000002" `
    -Headers @{
      apikey = $script:PublicKey
      Authorization = "Bearer $($student.access_token)"
    }
  Assert-CcStatus $crossTenant @(200) 'student cross-institution RLS request'
  Assert-Cc (@($crossTenant.Body).Count -eq 0) 'student cannot read another institution'

  foreach ($email in @(
    'member.suspended@campusconnect.local.invalid',
    'member.inactive-campus@campusconnect.local.invalid'
  )) {
    $session = $sessions[$email]
    $institutions = Invoke-CcHttp `
      -Method GET `
      -Uri "$($script:ApiUrl)/rest/v1/institutions?select=id,name" `
      -Headers @{
        apikey = $script:PublicKey
        Authorization = "Bearer $($session.access_token)"
      }
    Assert-CcStatus $institutions @(200) "$email institution RLS request"
    Assert-Cc (@($institutions.Body).Count -eq 0) "$email cannot directly read an institution"

    $profileAttempt = Invoke-CcRpc `
      $session `
      'complete_my_profile' `
      @{ new_display_name = 'Should Not Be Applied' }
    Assert-CcStatus $profileAttempt @(403) "$email profile completion rejected"
    Assert-Cc ($profileAttempt.Body.code -eq '42501') "$email profile denial SQLSTATE"
  }

  $validInvite = @($contexts['member.invited@campusconnect.local.invalid'].memberships)[0]
  $expiredInvite = @($contexts['member.expired-invite@campusconnect.local.invalid'].memberships)[0]
  Assert-Cc `
    (([datetime]$validInvite.invitation_expires_at).ToUniversalTime() -gt [datetime]::UtcNow) `
    'valid invitation is in the future'
  Assert-Cc `
    (([datetime]$expiredInvite.invitation_expires_at).ToUniversalTime() -le [datetime]::UtcNow) `
    'expired invitation is in the past'

  $expiredInviteSession = $sessions['member.expired-invite@campusconnect.local.invalid']
  $expiredAcceptance = Invoke-CcRpc `
    $expiredInviteSession `
    'accept_my_invitation' `
    @{
      target_membership_id = '30000000-0000-4000-8000-000000000005'
      new_display_name = 'Expired Student'
    }
  Assert-CcStatus $expiredAcceptance @(403) 'expired invitation rejected'
  Assert-Cc ($expiredAcceptance.Body.code -eq '42501') 'expired invitation SQLSTATE'
  $expiredAfter = Get-CcContext $expiredInviteSession
  Assert-Cc (@($expiredAfter.memberships)[0].status -eq 'invited') 'expired invitation remains invited'
  Assert-Cc ($null -eq $expiredAfter.profile.profile_completed_at) 'expired invitation does not complete profile'

  $bannedEmail = "banned.$([guid]::NewGuid().ToString('N'))@campusconnect.local.invalid"
  $adminHeaders = @{
    apikey = $script:ServiceRoleKey
    Authorization = "Bearer $($script:ServiceRoleKey)"
  }

  $passwordPolicyEmail = "password-policy.$([guid]::NewGuid().ToString('N'))@campusconnect.local.invalid"
  $passwordPolicyUserId = $null
  try {
    $createPasswordPolicyUser = Invoke-CcHttp `
      -Method POST `
      -Uri "$($script:ApiUrl)/auth/v1/admin/users" `
      -Headers $adminHeaders `
      -Body @{
        email = $passwordPolicyEmail
        password = $script:Password
        email_confirm = $true
      }
    Assert-CcStatus $createPasswordPolicyUser @(200) 'disposable password-policy user created'
    $passwordPolicyUserId = $createPasswordPolicyUser.Body.id
    Assert-Cc `
      (-not [string]::IsNullOrWhiteSpace($passwordPolicyUserId)) `
      'password-policy user ID returned'

    $passwordPolicySession = New-CcSession $passwordPolicyEmail
    $weakPasswordUpdate = Invoke-CcHttp `
      -Method PUT `
      -Uri "$($script:ApiUrl)/auth/v1/user" `
      -Headers @{
        apikey = $script:PublicKey
        Authorization = "Bearer $($passwordPolicySession.access_token)"
      } `
      -Body @{ password = 'Seven77' }
    Assert-CcStatus $weakPasswordUpdate @(400, 422) 'seven-character password rejected'
    Assert-Cc `
      ($weakPasswordUpdate.Body.error_code -eq 'weak_password') `
      'weak password uses password-policy response'
  }
  finally {
    if (-not [string]::IsNullOrWhiteSpace($passwordPolicyUserId)) {
      $deleted = Invoke-CcHttp `
        -Method DELETE `
        -Uri "$($script:ApiUrl)/auth/v1/admin/users/$passwordPolicyUserId" `
        -Headers $adminHeaders
      Assert-CcStatus $deleted @(200) 'disposable password-policy user removed'
    }
  }

  $bannedUserId = $null
  try {
    $createBanned = Invoke-CcHttp `
      -Method POST `
      -Uri "$($script:ApiUrl)/auth/v1/admin/users" `
      -Headers $adminHeaders `
      -Body @{
        email = $bannedEmail
        password = $script:Password
        email_confirm = $true
        ban_duration = '876000h'
      }
    Assert-CcStatus $createBanned @(200) 'disposable banned user created'
    $bannedUserId = $createBanned.Body.id
    Assert-Cc (-not [string]::IsNullOrWhiteSpace($bannedUserId)) 'banned user ID returned'

    $bannedLogin = Invoke-CcHttp `
      -Method POST `
      -Uri "$($script:ApiUrl)/auth/v1/token?grant_type=password" `
      -Headers @{ apikey = $script:PublicKey } `
      -Body @{ email = $bannedEmail; password = $script:Password }
    Assert-CcStatus $bannedLogin @(400) 'banned user login rejected'
    Assert-Cc ($bannedLogin.Body.error_code -eq 'user_banned') 'banned user receives banned error'
  }
  finally {
    if (-not [string]::IsNullOrWhiteSpace($bannedUserId)) {
      $deleted = Invoke-CcHttp `
        -Method DELETE `
        -Uri "$($script:ApiUrl)/auth/v1/admin/users/$bannedUserId" `
        -Headers $adminHeaders
      Assert-CcStatus $deleted @(200) 'disposable banned user removed'
    }
  }

  $faculty = New-CcSession 'faculty.active@campusconnect.local.invalid'
  $academicInstitutionId = '20000000-0000-4000-8000-000000000001'
  $academicDate = $null
  $distributedSystemsOfferingId = '45000000-0000-4000-8000-000000000001'
  $distributedSystemsTimetableId = $null
  $mobileDevelopmentOfferingId = '45000000-0000-4000-8000-000000000002'
  $activeStudentId = '10000000-0000-4000-8000-000000000001'
  $multiRoleUserId = '10000000-0000-4000-8000-000000000003'

  $studentDashboard = Invoke-CcRpc `
    $student `
    'get_my_academic_dashboard' `
    @{
      target_institution_id = $academicInstitutionId
      target_role = 'student'
      target_date = $academicDate
    }
  Assert-CcStatus $studentDashboard @(200) 'student academic dashboard returned'
  $academicDate = [string]$studentDashboard.Body.date
  $parsedAcademicDate = [datetime]::MinValue
  Assert-Cc `
    (
      -not [string]::IsNullOrWhiteSpace($academicDate) -and
      [datetime]::TryParseExact(
        $academicDate,
        'yyyy-MM-dd',
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None,
        [ref]$parsedAcademicDate
      )
    ) `
    'student dashboard returns institution-local today'
  Assert-Cc `
    ($studentDashboard.Body.institution_id -eq $academicInstitutionId) `
    'student dashboard institution is exact'
  Assert-Cc ($studentDashboard.Body.role -eq 'student') 'student dashboard role branch'
  Assert-Cc `
    ($studentDashboard.Body.time_zone -eq 'Asia/Kolkata') `
    'student dashboard institution time zone'

  $studentSchedule = @($studentDashboard.Body.schedule)
  Assert-Cc ($studentSchedule.Count -eq 2) 'student today dashboard has exactly two classes'
  Assert-CcSet `
    @($studentSchedule | ForEach-Object { $_.course_offering_id }) `
    @($distributedSystemsOfferingId, $mobileDevelopmentOfferingId) `
    'student today dashboard has exact offerings'
  $distributedSystemsClass = @(
    $studentSchedule |
      Where-Object { $_.course_offering_id -eq $distributedSystemsOfferingId }
  )[0]
  $mobileDevelopmentClass = @(
    $studentSchedule |
      Where-Object { $_.course_offering_id -eq $mobileDevelopmentOfferingId }
  )[0]
  $distributedSystemsTimetableId = [string]$distributedSystemsClass.timetable_entry_id
  Assert-Cc `
    (
      -not [string]::IsNullOrWhiteSpace($distributedSystemsTimetableId) -and
      $distributedSystemsClass.subject_code -eq 'CS701' -and
      $distributedSystemsClass.starts_at -eq '09:00' -and
      $distributedSystemsClass.ends_at -eq '10:00' -and
      $distributedSystemsClass.room -eq 'Innovation Lab'
    ) `
    'student Distributed Systems class details are exact'
  Assert-Cc `
    (
      $mobileDevelopmentClass.subject_code -eq 'CS702' -and
      $mobileDevelopmentClass.starts_at -eq '11:15' -and
      $mobileDevelopmentClass.ends_at -eq '12:15' -and
      $mobileDevelopmentClass.room -eq 'Mobile Studio'
    ) `
    'student Mobile Development class details are exact'
  Assert-Cc `
    (@($studentSchedule | Where-Object { $_.attendance_submitted }).Count -eq 0) `
    'student today classes initially have no attendance submission'

  $studentSummary = @($studentDashboard.Body.attendance_summary)
  Assert-Cc ($studentSummary.Count -eq 2) 'student dashboard has exactly two attendance summaries'
  Assert-CcSet `
    @($studentSummary | ForEach-Object { $_.subject_code }) `
    @('CS701', 'CS702') `
    'student dashboard has exact attendance subjects'
  $distributedSystemsSummary = @(
    $studentSummary | Where-Object { $_.course_offering_id -eq $distributedSystemsOfferingId }
  )[0]
  Assert-Cc `
    ($distributedSystemsSummary.attended_sessions -eq 2) `
    'student Distributed Systems attended count before submission'
  Assert-Cc `
    ($distributedSystemsSummary.total_sessions -eq 3) `
    'student Distributed Systems total count before submission'
  Assert-Cc `
    ($distributedSystemsSummary.excused_sessions -eq 0) `
    'student Distributed Systems excused count before submission'
  Assert-Cc `
    ([decimal]$distributedSystemsSummary.percentage -eq [decimal]66.67) `
    'student Distributed Systems percentage before submission'
  $mobileDevelopmentSummary = @(
    $studentSummary | Where-Object { $_.course_offering_id -eq $mobileDevelopmentOfferingId }
  )[0]
  Assert-Cc `
    ($mobileDevelopmentSummary.attended_sessions -eq 1) `
    'student Mobile Development attended count before submission'
  Assert-Cc `
    ($mobileDevelopmentSummary.total_sessions -eq 2) `
    'student Mobile Development total count before submission'
  Assert-Cc `
    ($mobileDevelopmentSummary.excused_sessions -eq 1) `
    'student Mobile Development excused count before submission'
  Assert-Cc `
    ([decimal]$mobileDevelopmentSummary.percentage -eq [decimal]50) `
    'student Mobile Development percentage before submission'

  $facultyDashboard = Invoke-CcRpc `
    $faculty `
    'get_my_academic_dashboard' `
    @{
      target_institution_id = $academicInstitutionId
      target_role = 'faculty'
      target_date = $academicDate
    }
  Assert-CcStatus $facultyDashboard @(200) 'faculty academic dashboard returned'
  Assert-Cc ($facultyDashboard.Body.role -eq 'faculty') 'faculty dashboard role branch'
  $facultySchedule = @($facultyDashboard.Body.schedule)
  Assert-Cc ($facultySchedule.Count -eq 2) 'faculty today dashboard has exactly two assigned classes'
  Assert-CcSet `
    @($facultySchedule | ForEach-Object { $_.course_offering_id }) `
    @($distributedSystemsOfferingId, $mobileDevelopmentOfferingId) `
    'faculty today dashboard has exact assigned offerings'
  Assert-Cc `
    (@($facultyDashboard.Body.attendance_summary).Count -eq 0) `
    'faculty dashboard does not expose a student attendance summary'
  foreach ($scheduledClass in $facultySchedule) {
    $roster = @($scheduledClass.roster)
    Assert-Cc `
      ($roster.Count -eq 2) `
      "faculty $($scheduledClass.subject_code) roster has exactly two students"
    Assert-CcSet `
      @($roster | ForEach-Object { $_.student_user_id }) `
      @($activeStudentId, $multiRoleUserId) `
      "faculty $($scheduledClass.subject_code) roster has exact students"
    Assert-Cc `
      (@($roster | Where-Object { $null -ne $_.status }).Count -eq 0) `
      "faculty $($scheduledClass.subject_code) roster is initially unmarked"
  }

  $multiRole = $sessions['member.multi-role@campusconnect.local.invalid']
  $multiStudentDashboard = Invoke-CcRpc `
    $multiRole `
    'get_my_academic_dashboard' `
    @{
      target_institution_id = $academicInstitutionId
      target_role = 'student'
      target_date = $academicDate
    }
  Assert-CcStatus $multiStudentDashboard @(200) 'multi-role student dashboard returned'
  Assert-Cc `
    ($multiStudentDashboard.Body.role -eq 'student') `
    'multi-role student branch is explicit'
  Assert-Cc `
    (@($multiStudentDashboard.Body.schedule).Count -eq 2) `
    'multi-role student branch has both enrolled classes'
  Assert-Cc `
    (@($multiStudentDashboard.Body.attendance_summary).Count -eq 2) `
    'multi-role student branch includes personal attendance summaries'

  $multiFacultyDashboard = Invoke-CcRpc `
    $multiRole `
    'get_my_academic_dashboard' `
    @{
      target_institution_id = $academicInstitutionId
      target_role = 'faculty'
      target_date = $academicDate
    }
  Assert-CcStatus $multiFacultyDashboard @(200) 'multi-role faculty dashboard returned'
  Assert-Cc `
    ($multiFacultyDashboard.Body.role -eq 'faculty') `
    'multi-role faculty branch is explicit'
  $multiFacultySchedule = @($multiFacultyDashboard.Body.schedule)
  Assert-Cc `
    ($multiFacultySchedule.Count -eq 1) `
    'multi-role faculty branch has only the assigned class'
  Assert-Cc `
    ($multiFacultySchedule[0].course_offering_id -eq $distributedSystemsOfferingId) `
    'multi-role faculty branch has exact assigned offering'
  Assert-Cc `
    (@($multiFacultySchedule[0].roster).Count -eq 2) `
    'multi-role faculty branch includes the assigned roster'
  Assert-Cc `
    (@($multiFacultyDashboard.Body.attendance_summary).Count -eq 0) `
    'multi-role faculty branch omits student attendance summaries'

  $academicCrossTenant = Invoke-CcRpc `
    $student `
    'get_my_academic_dashboard' `
    @{
      target_institution_id = '20000000-0000-4000-8000-000000000002'
      target_role = 'student'
      target_date = $academicDate
    }
  Assert-CcStatus $academicCrossTenant @(403) 'academic dashboard rejects cross-tenant access'
  Assert-Cc `
    ($academicCrossTenant.Body.code -eq '42501') `
    'academic cross-tenant denial SQLSTATE'

  $academicRecovery = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/rest/v1/rpc/get_my_academic_dashboard" `
    -Headers @{
      apikey = $script:PublicKey
      Authorization = "Bearer $recoveryToken"
    } `
    -Body @{
      target_institution_id = $academicInstitutionId
      target_role = 'student'
      target_date = $academicDate
    }
  Assert-CcStatus $academicRecovery @(403) 'OTP recovery token cannot call academic dashboard'
  Assert-Cc `
    ($academicRecovery.Body.code -eq '42501') `
    'OTP academic dashboard denial SQLSTATE'

  $academicIsoWeekday = if ($parsedAcademicDate.DayOfWeek -eq 0) {
    7
  }
  else {
    [int]$parsedAcademicDate.DayOfWeek
  }
  $distributedSystemsTimetableId = '59000000-0000-4000-8000-000000000010'
  $verificationTimetableInsert = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/rest/v1/timetable_entries" `
    -Headers $adminHeaders `
    -Body @{
      id = $distributedSystemsTimetableId
      institution_id = $academicInstitutionId
      academic_period_id = '42000000-0000-4000-8000-000000000001'
      course_offering_id = $distributedSystemsOfferingId
      weekday = $academicIsoWeekday
      starts_at = '00:00:00'
      ends_at = '01:00:00'
      room = 'Verification Room'
    }
  Assert-CcStatus `
    $verificationTimetableInsert `
    @(201) `
    'verifier class is created behind institution-local current time'

  $attendanceRequestId = '59000000-0000-4000-8000-000000000001'
  $attendancePayload = @(
    @{
      student_user_id = $activeStudentId
      status = 'absent'
    },
    @{
      student_user_id = $multiRoleUserId
      status = 'present'
    }
  )
  $attendanceSubmissionParameters = @{
    target_institution_id = $academicInstitutionId
    target_course_offering_id = $distributedSystemsOfferingId
    target_timetable_entry_id = $distributedSystemsTimetableId
    target_session_date = $academicDate
    attendance_payload = $attendancePayload
    request_id = $attendanceRequestId
  }
  $attendanceSubmission = Invoke-CcRpc `
    $faculty `
    'submit_attendance' `
    $attendanceSubmissionParameters
  Assert-CcStatus $attendanceSubmission @(200) 'faculty attendance submission accepted'
  $submittedClass = @(
    @($attendanceSubmission.Body.schedule) |
      Where-Object { $_.timetable_entry_id -eq $distributedSystemsTimetableId }
  )[0]
  Assert-Cc `
    ([bool]$submittedClass.attendance_submitted) `
    'faculty submission confirms Distributed Systems attendance'
  Assert-Cc `
    (-not [string]::IsNullOrWhiteSpace([string]$submittedClass.attendance_session_id)) `
    'faculty submission returns an attendance session ID'
  $submittedSessionId = [string]$submittedClass.attendance_session_id
  $submittedRoster = @($submittedClass.roster)
  Assert-Cc ($submittedRoster.Count -eq 2) 'faculty submission returns the exact roster size'
  $submittedStudent = @(
    $submittedRoster | Where-Object { $_.student_user_id -eq $activeStudentId }
  )[0]
  $submittedMultiRole = @(
    $submittedRoster | Where-Object { $_.student_user_id -eq $multiRoleUserId }
  )[0]
  Assert-Cc ($submittedStudent.status -eq 'absent') 'faculty submission stores student absence'
  Assert-Cc ($submittedMultiRole.status -eq 'present') 'faculty submission stores multi-role presence'

  $attendanceReplay = Invoke-CcRpc `
    $faculty `
    'submit_attendance' `
    $attendanceSubmissionParameters
  Assert-CcStatus $attendanceReplay @(200) 'same attendance request replays successfully'
  $replayedClass = @(
    @($attendanceReplay.Body.schedule) |
      Where-Object { $_.timetable_entry_id -eq $distributedSystemsTimetableId }
  )[0]
  Assert-Cc `
    ($replayedClass.attendance_session_id -eq $submittedSessionId) `
    'same attendance request returns the original session'

  $mismatchedReplay = Invoke-CcRpc `
    $faculty `
    'submit_attendance' `
    @{
      target_institution_id = $academicInstitutionId
      target_course_offering_id = $distributedSystemsOfferingId
      target_timetable_entry_id = $distributedSystemsTimetableId
      target_session_date = $academicDate
      attendance_payload = @(
        @{ student_user_id = $activeStudentId; status = 'present' },
        @{ student_user_id = $multiRoleUserId; status = 'present' }
      )
      request_id = $attendanceRequestId
    }
  Assert-CcStatus $mismatchedReplay @(400) 'mismatched same-key attendance replay rejected'
  Assert-Cc `
    ($mismatchedReplay.Body.code -eq '22023') `
    'mismatched same-key attendance SQLSTATE'

  $duplicateSession = Invoke-CcRpc `
    $faculty `
    'submit_attendance' `
    @{
      target_institution_id = $academicInstitutionId
      target_course_offering_id = $distributedSystemsOfferingId
      target_timetable_entry_id = $distributedSystemsTimetableId
      target_session_date = $academicDate
      attendance_payload = $attendancePayload
      request_id = '59000000-0000-4000-8000-000000000002'
    }
  Assert-CcStatus $duplicateSession @(409) 'different-key duplicate attendance session rejected'
  Assert-Cc `
    ($duplicateSession.Body.code -eq '23505') `
    'different-key duplicate attendance SQLSTATE'

  $studentRefresh = Invoke-CcRpc `
    $student `
    'get_my_academic_dashboard' `
    @{
      target_institution_id = $academicInstitutionId
      target_role = 'student'
      target_date = $academicDate
    }
  Assert-CcStatus $studentRefresh @(200) 'student dashboard refresh after faculty submission'
  $refreshedStudentClass = @(
    @($studentRefresh.Body.schedule) |
      Where-Object { $_.timetable_entry_id -eq $distributedSystemsTimetableId }
  )[0]
  Assert-Cc `
    ([bool]$refreshedStudentClass.attendance_submitted) `
    'student refresh sees the confirmed attendance session'
  Assert-Cc `
    ($refreshedStudentClass.attendance_session_id -eq $submittedSessionId) `
    'student refresh sees the exact attendance session'
  $refreshedSummary = @(
    @($studentRefresh.Body.attendance_summary) |
      Where-Object { $_.course_offering_id -eq $distributedSystemsOfferingId }
  )[0]
  Assert-Cc `
    ($refreshedSummary.attended_sessions -eq 2) `
    'student refresh preserves Distributed Systems attended count after absence'
  Assert-Cc `
    ($refreshedSummary.total_sessions -eq 4) `
    'student refresh increments Distributed Systems total count'
  Assert-Cc `
    ($refreshedSummary.excused_sessions -eq 0) `
    'student refresh preserves Distributed Systems excused count'
  Assert-Cc `
    ([decimal]$refreshedSummary.percentage -eq [decimal]50) `
    'student refresh recalculates Distributed Systems percentage'

  $studentAttendanceRecord = Invoke-CcHttp `
    -Method GET `
    -Uri "$($script:ApiUrl)/rest/v1/attendance_records?select=session_id,student_user_id,status&session_id=eq.$submittedSessionId" `
    -Headers @{
      apikey = $script:PublicKey
      Authorization = "Bearer $($student.access_token)"
    }
  Assert-CcStatus $studentAttendanceRecord @(200) 'student reads own submitted attendance record'
  Assert-Cc `
    (@($studentAttendanceRecord.Body).Count -eq 1) `
    'student attendance RLS returns only the personal record'
  Assert-Cc `
    (@($studentAttendanceRecord.Body)[0].student_user_id -eq $activeStudentId) `
    'student attendance RLS record has the authenticated student'
  Assert-Cc `
    (@($studentAttendanceRecord.Body)[0].status -eq 'absent') `
    'student refresh sees the submitted absence status'

  $refreshed = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/auth/v1/token?grant_type=refresh_token" `
    -Headers @{ apikey = $script:PublicKey } `
    -Body @{ refresh_token = $faculty.refresh_token }
  Assert-CcStatus $refreshed @(200) 'valid refresh token accepted'
  $logout = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/auth/v1/logout" `
    -Headers @{
      apikey = $script:PublicKey
      Authorization = "Bearer $($refreshed.Body.access_token)"
    }
  Assert-CcStatus $logout @(200, 204) 'session logout accepted'
  $revokedRefresh = Invoke-CcHttp `
    -Method POST `
    -Uri "$($script:ApiUrl)/auth/v1/token?grant_type=refresh_token" `
    -Headers @{ apikey = $script:PublicKey } `
    -Body @{ refresh_token = $refreshed.Body.refresh_token }
  Assert-CcStatus $revokedRefresh @(400) 'logged-out refresh token rejected'

  if (-not $SkipRecovery) {
    $recoveryEmail = 'student.active@campusconnect.local.invalid'
    $before = Invoke-CcHttp -Method GET -Uri "$($script:MailUrl)/api/v1/message/latest"
    $beforeId = if ($before.Status -eq 200) { $before.Body.ID } else { $null }
    $redirect = [uri]::EscapeDataString('campusconnect://auth-callback')
    $recovery = Invoke-CcHttp `
      -Method POST `
      -Uri "$($script:ApiUrl)/auth/v1/recover?redirect_to=$redirect" `
      -Headers @{ apikey = $script:PublicKey } `
      -Body @{ email = $recoveryEmail }
    Assert-CcStatus $recovery @(200) 'password recovery request accepted'

    $mail = $null
    for ($attempt = 0; $attempt -lt 20; $attempt += 1) {
      Start-Sleep -Milliseconds 500
      $candidate = Invoke-CcHttp -Method GET -Uri "$($script:MailUrl)/api/v1/message/latest"
      if ($candidate.Status -eq 200 -and $candidate.Body.ID -ne $beforeId) {
        $mail = $candidate
        break
      }
    }
    Assert-Cc ($null -ne $mail) 'new recovery message captured by Mailpit'
    $recipients = @(@($mail.Body.To) | ForEach-Object { $_.Address })
    Assert-Cc ($recipients -contains $recoveryEmail) 'recovery message addressed to seeded user'
    $content = [Net.WebUtility]::HtmlDecode("$($mail.Body.Text)`n$($mail.Body.HTML)")
    $decodedContent = [uri]::UnescapeDataString($content)
    Assert-Cc ($decodedContent -match '/auth/v1/verify\?') 'recovery message contains Auth verification URL'
    Assert-Cc ($decodedContent -match 'type=recovery') 'recovery URL has recovery type'
    Assert-Cc `
      ($decodedContent -match 'campusconnect://auth-callback') `
      'recovery URL targets the app callback'
  }

  if (-not $SkipInvitationMutation) {
    $invitedSession = $sessions['member.invited@campusconnect.local.invalid']
    $accepted = Invoke-CcRpc `
      $invitedSession `
      'accept_my_invitation' `
      @{
        target_membership_id = '30000000-0000-4000-8000-000000000004'
        new_display_name = '  Local Invited Student  '
      }
    Assert-CcStatus $accepted @(200) 'valid invitation accepted'
    Assert-Cc `
      ($accepted.Body.profile.display_name -eq 'Local Invited Student') `
      'accepted display name normalized'
    Assert-Cc `
      ($null -ne $accepted.Body.profile.profile_completed_at) `
      'acceptance completes profile'
    Assert-Cc `
      (@($accepted.Body.memberships)[0].status -eq 'active') `
      'accepted membership becomes active'

    $replay = Invoke-CcRpc `
      $invitedSession `
      'accept_my_invitation' `
      @{
        target_membership_id = '30000000-0000-4000-8000-000000000004'
        new_display_name = 'Replay Attempt'
      }
    Assert-CcStatus $replay @(403) 'accepted invitation replay rejected'
    Assert-Cc ($replay.Body.code -eq '42501') 'replay SQLSTATE'
  }

}
catch {
  $suiteError = $_
}
finally {
  try {
    if (-not $KeepMutatedState) {
      Reset-CcDatabase
    }
  }
  catch {
    $cleanupError = $_
  }
  finally {
    Pop-Location
  }
}

if ($null -ne $suiteError) {
  if ($null -ne $cleanupError) {
    Write-Warning "The smoke suite failed and deterministic cleanup also failed: $($cleanupError.Exception.Message)"
  }
  throw $suiteError
}

if ($null -ne $cleanupError) {
  throw $cleanupError
}

Write-Host "Local backend smoke suite passed: $script:AssertionCount assertions." -ForegroundColor Cyan
