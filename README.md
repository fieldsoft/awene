# Awene

Menkayonta is offline first. When a project is shared, centralization
may be required. This service provides an HTTP API for managing databases
and users.

- It provides a means of allowing limited admin-level configuration of
  a couchdb server.
- Users and roles can be managed within the context of an
  organization, which may have multiple databases and projects.
- JWTs are provided that may be used to authenticate with couchdb and
  ensure correct authorizations.

It is expected that admins will use the Menkayonta UI to interact with
the HTTP API.
