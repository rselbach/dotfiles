---
name: atlassian-mcp
description: Guide for using the Atlassian Rovo MCP server tools for Jira, Confluence, Compass, and Teamwork Graph. Use when querying Jira issues, Confluence pages, searching with JQL/CQL, creating or updating work items, or reasoning about relationships between Atlassian entities.
---

# Atlassian Rovo MCP

## Overview

This skill covers using the Atlassian Rovo MCP tools for Jira, Confluence, Compass, and Teamwork Graph. All tools are accessed through `tools["atlassian"]` in the Code Mode runtime.

## Authentication

OAuth 2.1 flow with PKCE:

```bash
opencode2 mcp auth atlassian
```

Stored credentials can be removed with:

```bash
opencode2 mcp logout atlassian
```

## First Call: Get Cloud ID

Every tool call (except `atlassianUserInfo` and `search`) needs a `cloudId`. Start here:

```js
const resources = await tools["atlassian"].getAccessibleAtlassianResources({});
// Extract cloudId: resources[0].id
```

The cloudId is a UUID (e.g., `6b5964a0-ccc8-4c3b-b0d6-5c5284cacadf`).

## User Info

```js
const me = await tools["atlassian"].atlassianUserInfo({});
// Returns: account_id, name, email, locale, etc.
```

## Jira Tools

### Searching Issues (JQL)

Use `searchJiraIssuesUsingJql` — NOT the Rovo `search` tool. Rovo `search` is for natural language across all products and returns Confluence-heavy results.

```js
// Get your open issues
const result = JSON.parse(await tools["atlassian"].searchJiraIssuesUsingJql({
  cloudId: "YOUR_CLOUD_ID",
  jql: "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
  maxResults: 50,
}));
result.issues.map(i => ({
  key: i.key,
  summary: i.fields.summary,
  status: i.fields.status?.name,
  priority: i.fields.priority?.name,
  project: i.fields.project?.key,
  issuetype: i.fields.issuetype?.name,
}));
```

**Key JQL patterns:**
- `assignee = currentUser() AND statusCategory != Done` — my open issues
- `assignee = currentUser() AND resolution = Unresolved` — my unresolved
- `project = PROJ AND status = "In Progress"` — project filter
- `sprint in openSprints() AND assignee = currentUser()` — current sprint
- `status changed to Done AFTER startOfDay("-7d")` — recently resolved

**Parameters:**
- `cloudId`: required, from `getAccessibleAtlassianResources`
- `jql`: JQL query string
- `maxResults`: 50-100
- `fields`: array of field names, or `["*all"]` for everything
- `responseContentFormat`: `"markdown"` or `"adf"` (default)
- `searchResultMode`: `"issues"` (default), `"count"`, or `"all"`

### Getting an Issue

```js
const issue = JSON.parse(await tools["atlassian"].getJiraIssue({
  cloudId: "YOUR_CLOUD_ID",
  issueIdOrKey: "PROJ-123",
  fields: ["*all"],
}));
```

### Creating an Issue

```js
await tools["atlassian"].createJiraIssue({
  cloudId: "YOUR_CLOUD_ID",
  projectKey: "PROJ",
  issueTypeName: "Task",
  summary: "Do the thing",
  description: "Details in markdown",
  assignee_account_id: "5fce36cf...",
  // For custom fields, priority, components, labels:
  additional_fields: {
    priority: { name: "High" },
    labels: ["frontend"],
    components: [{ name: "Backend" }],
  },
});
```

Get field metadata first:

```js
const meta = JSON.parse(await tools["atlassian"].getJiraIssueTypeMetaWithFields({
  cloudId: "YOUR_CLOUD_ID",
  projectIdOrKey: "PROJ",
  issueTypeId: "10001",
}));
```

### Editing an Issue

```js
await tools["atlassian"].editJiraIssue({
  cloudId: "YOUR_CLOUD_ID",
  issueIdOrKey: "PROJ-123",
  fields: {
    summary: "New summary",
    priority: { name: "High" },
    // Clear a field with null
    resolution: null,
  },
});
```

### Transitioning an Issue

```js
// Get available transitions first
const transitions = JSON.parse(await tools["atlassian"].getTransitionsForJiraIssue({
  cloudId: "YOUR_CLOUD_ID",
  issueIdOrKey: "PROJ-123",
}));

// Then apply one
await tools["atlassian"].transitionJiraIssue({
  cloudId: "YOUR_CLOUD_ID",
  issueIdOrKey: "PROJ-123",
  transition: { id: "41" },
});
```

### Comments

```js
// Add comment
await tools["atlassian"].addCommentToJiraIssue({
  cloudId: "YOUR_CLOUD_ID",
  issueIdOrKey: "PROJ-123",
  commentBody: "This is a comment",
});

// Update existing comment (add commentId)
```

### Time Tracking

```js
await tools["atlassian"].addWorklogToJiraIssue({
  cloudId: "YOUR_CLOUD_ID",
  issueIdOrKey: "PROJ-123",
  timeSpent: "2h",
  commentBody: "Worked on feature",
  started: "2026-08-07T09:00:00.000+0000",
});
```

### Issue Links

```js
// Get link types
const linkTypes = await tools["atlassian"].getIssueLinkTypes({ cloudId });

// Create link (inward = blocking issue, outward = blocked issue)
await tools["atlassian"].createIssueLink({
  cloudId: "YOUR_CLOUD_ID",
  inwardIssue: "PROJ-123",
  outwardIssue: "PROJ-456",
  type: "Blocks",
});
```

### Looking Up Users

```js
const users = await tools["atlassian"].lookupJiraAccountId({
  cloudId: "YOUR_CLOUD_ID",
  searchString: "roberto",
});
```

### Listing Projects

```js
const projects = JSON.parse(await tools["atlassian"].getVisibleJiraProjects({
  cloudId: "YOUR_CLOUD_ID",
}));
```

## Confluence Tools

### Searching Confluence (CQL)

```js
const result = JSON.parse(await tools["atlassian"].searchConfluenceUsingCql({
  cloudId: "YOUR_CLOUD_ID",
  cql: "space = SPG AND type = page AND title ~ \"onboarding\"",
  limit: 25,
}));
```

Or use Rovo search for natural language:

```js
const result = JSON.parse(await tools["atlassian"].search({
  query: "onboarding docs for new engineers",
}));
```

### Getting a Page

```js
const page = await tools["atlassian"].fetch({
  id: "ari:cloud:confluence:cloudId:page/123456789",
});
```

### Getting Pages in a Space

```js
const pages = JSON.parse(await tools["atlassian"].getPagesInConfluenceSpace({
  cloudId: "YOUR_CLOUD_ID",
  spaceKey: "SPG",
  limit: 50,
}));
```

### Getting Descendants

```js
const children = await tools["atlassian"].getConfluencePageDescendants({
  cloudId: "YOUR_CLOUD_ID",
  pageId: "123456789",
  limit: 50,
});
```

### Creating/Updating Pages

```js
await tools["atlassian"].createConfluencePage({
  cloudId: "YOUR_CLOUD_ID",
  spaceId: "12345",
  title: "Page Title",
  content: "**Bold** markdown content",
});

await tools["atlassian"].updateConfluencePage({
  cloudId: "YOUR_CLOUD_ID",
  pageId: "123456789",
  title: "Updated Title",
  content: "Updated content",
  version: 2,
});
```

### Comments

```js
// Get footer comments
await tools["atlassian"].getConfluencePageFooterComments({
  cloudId: "YOUR_CLOUD_ID",
  pageId: "123456789",
});

// Create footer comment
await tools["atlassian"].createConfluenceFooterComment({
  cloudId: "YOUR_CLOUD_ID",
  pageId: "123456789",
  content: "A comment",
});
```

### Listing Spaces

```js
const spaces = JSON.parse(await tools["atlassian"].getConfluenceSpaces({
  cloudId: "YOUR_CLOUD_ID",
  limit: 50,
}));
```

## Rovo Search (Cross-Product)

Use for natural language queries across Jira + Confluence:

```js
const result = JSON.parse(await tools["atlassian"].search({
  query: "what's the status of the auth0 migration project",
}));
// Results include type: "issue" | "page" | "blogpost"
```

## Teamwork Graph (Beta)

Use for reasoning about relationships between entities. After calling `getTeamworkGraphContext`, hydrate linked objects with `getTeamworkGraphObject`.

```js
// Get context around a work item
const context = await tools["atlassian"].getTeamworkGraphContext({
  cloudId: "YOUR_CLOUD_ID",
  query: "PROJ-123",
});

// Hydrate linked objects
const details = await tools["atlassian"].getTeamworkGraphObject({
  cloudId: "YOUR_CLOUD_ID",
  objects: [
    "ari:cloud:jira:cloudId:issue/12345",
    "ari:cloud:confluence:cloudId:page/67890",
  ],
});
```

Entry points: issues, projects, sprints, versions, comments, pages, blogposts, spaces, users, teams, PRs, repos, deployments, services, builds, Compass components, incidents.

## Compass Tools

```js
// List component types
const types = await tools["atlassian"].getCompassComponentTypes({ cloudId });

// Search components
const components = JSON.parse(await tools["atlassian"].getCompassComponents({
  cloudId: "YOUR_CLOUD_ID",
}));

// Create component
await tools["atlassian"].createCompassComponent({
  cloudId: "YOUR_CLOUD_ID",
  name: "my-service",
  typeId: "service",
});

// Custom fields
await tools["atlassian"].createCompassCustomFieldDefinition({
  cloudId: "YOUR_CLOUD_ID",
  input: {
    name: "Deployment URL",
    type: "TEXT",
  },
});
```

## Content Format

Two formats available for descriptions and comments:
- `"markdown"` — simple markdown text
- `"adf"` — Atlassian Document Format (JSON)

Use markdown unless you need precise formatting control.

## Key Differences from Rovo Search

| Need | Tool | Why |
|---|---|---|
| Find issues by JQL | `searchJiraIssuesUsingJql` | Precise, structured queries |
| Find Confluence by CQL | `searchConfluenceUsingCql` | Structured space/page queries |
| Natural language search | `search` (Rovo) | Cross-product, fuzzy |
| Get single entity by ARI | `fetch` | Direct lookup |
| Relationship context | `getTeamworkGraphContext` | Connected data |

## Tips

- Always call `getAccessibleAtlassianResources` first to get the cloudId
- Use `JSON.parse()` on `searchJiraIssuesUsingJql` results — it returns a JSON string
- For open issues, use `statusCategory != Done` rather than `resolution = Unresolved` (handles issues that were never resolved better)
- Rovo `search` results include a `type` field: `"issue"`, `"page"`, or `"blogpost"` — filter on it
- When creating issues, call `getJiraIssueTypeMetaWithFields` first to know what fields are available and required
- `searchAtlassian` (the beta `search` tool) does NOT need a cloudId — it's derived from your token
