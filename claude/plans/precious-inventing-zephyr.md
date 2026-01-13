# Single Post Page Redesign: Add Sidebar

## Goal
Improve readability of single blog posts by:
1. Constraining content width (~65ch for optimal reading)
2. Adding a sticky right sidebar with post metadata (title, author, date, tags)

## Design Reference
Simon Willison's blog: content on left, metadata sidebar on right that stays visible while scrolling.

## Files to Modify

1. **`themes/rselbach/layouts/_default/single.html`**
   - Wrap article in a two-column flex container
   - Add `<aside>` element for sidebar with:
     - "This is **{Title}** by Roberto Selbach, posted on {Date}."
     - Tag pills (linking to tag pages)

2. **`themes/rselbach/static/css/style.css`**
   - Add `.post-layout` two-column flex container
   - Add `.post-sidebar` styles (sticky positioning, typography)
   - Add sidebar-specific tag pill styles
   - Constrain `.post-content` max-width for readability
   - Responsive: stack sidebar above/below content on mobile

## Implementation Details

### Template Structure (single.html)
```html
{{ define "main" }}
<div class="post-layout">
  <article class="post">
    <header class="post-header">
      <h1 class="post-title">{{ .Title }}</h1>
    </header>
    <div class="post-content">
      {{ .Content }}
    </div>
  </article>

  {{ if eq .Section "blog" }}
  <aside class="post-sidebar">
    <div class="sidebar-meta">
      <p>This is <strong>{{ .Title }}</strong> by Roberto Selbach,
         posted on <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "January 2, 2006" }}</time>.</p>
    </div>
    {{ with .Params.tags }}
    <div class="sidebar-tags">
      {{ range . }}
      <a href="{{ "tags/" | absURL }}{{ . | urlize }}/" class="sidebar-tag">{{ . }}</a>
      {{ end }}
    </div>
    {{ end }}
  </aside>
  {{ end }}
</div>
{{ end }}
```

### CSS Approach
- Flex container with `gap` between columns
- Main article: `flex: 1` with `max-width: 65ch` for readability
- Sidebar: `width: 280px`, `position: sticky`, `top: 2rem`
- Sidebar tags: same pill style as existing, maybe slightly smaller
- Mobile breakpoint (<768px): hide sidebar entirely with `display: none`

## Verification
1. Run `hugo server` and check a blog post
2. Verify sidebar sticks while scrolling
3. Test mobile layout (resize browser < 768px)
4. Verify tag links work
5. Check non-blog pages (About) don't show sidebar
