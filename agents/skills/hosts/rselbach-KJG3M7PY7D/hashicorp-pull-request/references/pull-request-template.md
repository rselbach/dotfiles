## CHANGELOG

no-impact/Added/Changed/Deprecated/Removed/Fixed/Security

Describe how these changes affect customers or clients in one line. Start the
line with one of the verbs above. If these changes do not impact the
customer/client, then this line should read CHANGELOG: no-impact

## Description

--> ADD-JIRA-ISSUE-ID-AND-LINK

Add a short description here, that summarizes why this change is done.

## External Links

Add any external links that could help in reviewing this PR here.

## Deployment Standard Operating Procedures
[View full deployment guide](https://hashicorp.atlassian.net/wiki/spaces/CLOUD/pages/3961651209/HCP+Identity+Service+Deployment+Best+Practice)

# Testing
<!--
Please provide a short introduction on how to test this change or how this was tested.
-->

- [ ] If applicable, I've tested the code changes introduced as part of this pull request.

# :warning: Migrations
<!--
It is a good idea to isolate migrations from code changes by splitting them into
a separate PR. This reduces the risk of failed or missed migrations causing issues
in code that depends on them. Please consider doing this if possible.
-->

- [ ] This PR has no migrations.

**OR**

- [ ] This PR _has_ migrations, and I have tested them locally/in PRDE.
- [ ] Migrations are isolated, with related code changes in a separate PR.
        - Removing columns/tables: remove code reference first in one PR, then separate PR for migration.
        - Adding columns/tables: add new DB migration in one PR, then separate PR for code changes.
- [ ] I have merged or rebased against the latest `main` to ensure correct migration ordering.

# :flags: Feature Flag
<!-- Include any related feature flag names. -->

- [ ] These changes have no related feature flag.

**OR**

- [ ] These changes _have_ a feature flag, and I have tested all variations of it in lower environments.
- [ ] I have verified the feature flag's intended assignment in all environments.

# PR Rollback Readiness
- [ ] I have determined whether breakglass deployment or manual revert is best suited for these changes in the event of an incident.
- [ ] I have reviewed [breakglass deployment procedure](https://hashicorp.atlassian.net/wiki/spaces/CLOUD/pages/2637889634/HCP+Service+Deployment+Break+Glass+procedure) in the event an incident is triggered or can otherwise manually revert.

# PCI review checklist

<!-- heimdall_github_prtemplate:grc-pci_dss-2024-01-05 -->

- [ ] If applicable, I’ve documented a plan to revert these changes if they require more than reverting the pull request.
- [ ] If applicable, I’ve worked with GRC to document the impact of any changes to security controls.
- [ ] If applicable, I’ve worked with GRC to ensure compliance due to a significant change to the cardholder data environment.

<!--
- Examples of changes to controls include access controls, encryption, logging, etc.

- Examples of changes to cardholder data environment include changes to the
  operating systems, ports, protocols, services, cryptography-related components,
  PII processing code, etc.

If you have any questions, please contact your direct supervisor, GRC (#team-grc), or the PCI working group (#proj-pci-core).
-->
