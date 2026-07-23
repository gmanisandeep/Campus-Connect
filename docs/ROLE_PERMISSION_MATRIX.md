# Role and permission matrix

Permissions are granular capabilities, not hardcoded role strings. Roles below
are assignable templates; resource rules still apply. A user can hold multiple
roles per institution. This table is a target policy contract, not proof that
every listed capability has a migration or role-permission assignment.

| Capability | Platform admin | Institution admin | Dept admin | Faculty | Mentor | Placement | Club coord. | Student |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Manage institutions | Scoped | No | No | No | No | No | No | No |
| Manage institution settings | No | Yes | No | No | No | No | No | No |
| Manage department academics | No | Yes | Assigned dept | No | No | No | No | No |
| View course roster | Support-only audited | Yes | Assigned dept | Assigned course | Assigned mentees only | No | No | Self only |
| Record attendance | No | Override audited | Assigned dept | Assigned course | No | No | No | No |
| View attendance detail | No | Authorized report | Assigned dept | Assigned course | Assigned mentees if granted | No | No | Self only |
| View official Feed | Authorized support only | Authorized audience | Authorized audience | Authorized audience | Authorized audience | Authorized audience | Authorized audience | Authorized audience |
| Publish announcement | No | Institution | Department | Permitted audience | Mentees if granted | Career audience | Assigned clubs | No |
| Read/send course Chat | No | No by default | No by default | Assigned course | No | No | No | Enrolled course |
| Manage events | No | Institution | Department | Assigned events | No | Career events | Assigned clubs | No |
| Register for event | No | Optional | Optional | Optional | Optional | Optional | Optional | Self |
| Manage mentorship | No | Assign only | Assign in dept | If mentor role | Assigned mentees | No | No | View shared self |
| Manage opportunities | No | Institution | Optional | No | No | Institution scope | No | No |
| Maintain skill profile | No | No | No | No | No | No | No | Self |
| Save/apply to opportunity | No | No | No | No | No | No | No | Self, if eligible |
| Manage clubs | No | Institution | Optional | If assigned | No | No | Assigned clubs | Membership actions |
| View audit logs | Support-only audited | Institution | Department subset | Own actions | Own actions | Own actions | Own actions | Own actions/export |

Platform support access requires explicit time-bound elevation, reason, approval where applicable, and immutable auditing. It is never implicit in the platform administrator role.
