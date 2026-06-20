# Figma MCP Design-to-Code Rules

> Style: **Balanced** | CSS: **Tailwind CSS** | Framework: **Next.js** | Components: **Component First**

## Figma MCP Workflow (do not skip steps)

1. Run `get_design_context` first to fetch structured design data for target nodes
2. If response is truncated, run `get_metadata` for the high-level node map, then re-fetch specific nodes
3. Run `get_screenshot` for visual reference of the exact variant being implemented
4. Download any assets from the MCP assets endpoint before coding
5. Implement the design following the rules below
6. Validate against Figma screenshot for visual parity before marking complete

## Rate Limits & Dual Server Strategy

This project has **two MCP servers** configured. Both share the same Figma API rate limits (based on your plan/seat).

| Server | Use For |
|---|---|
| **framelink** (Framelink) | Daily design-to-code reads: `get_design_context`, `get_screenshot`, `get_metadata` — 25% smaller output, better AI accuracy |
| **figma** (Official Remote) | Write-to-canvas, design system tools: `generate_figma_design`, `search_design_system`, `get_variable_defs`, `create_design_system_rules` |

### Routing Rules
- **Default to Framelink** for all read operations (fetching design data, screenshots, metadata)
- **Use Official only** when you need: write-to-canvas, Figma Variables lookup, or design system search
- The exempt tools on Official (`add_code_connect_map`, `generate_figma_design`, `whoami`) do not count toward rate limits
- If either server returns a 429 rate limit error, switch to the **SVG Fallback** workflow described below

## Style Mode: Balanced

This project uses **balanced** mode. Follow Figma structure but snap values to the nearest design tokens.

- Structure and layout must match Figma (element hierarchy, nesting, ordering)
- Numeric values (spacing, font-size, border-radius) should snap to the **nearest existing design token** in the project
  - Example: Figma says 13px, project tokens have 12/14 → use 14
  - Example: Figma says #1a1a1a, project token has --color-gray-900: #1b1b1b → use the token
- If no matching token exists within a reasonable range (±2px for spacing, ±1 step for type scale), use the Figma value directly
- Colors should be matched to the nearest token in the project's color palette; if no match within ΔE < 5, use the Figma hex
- Prefer semantic token names (--spacing-md, --color-text-primary) over raw values

## Responsive Design Strategy

### Viewport Detection
- If Figma only contains a **desktop-width frame** (≥1024px):
  1. **Ask the user**: "I only see a desktop design — is there a mobile version?"
  2. If no mobile version exists, implement responsive scaling using the framework's grid/breakpoint system
  3. Stack horizontal layouts into single-column below the tablet breakpoint
- If Figma only contains a **mobile-width frame** (<768px):
  1. Assume this is a **mobile-only** single-column layout
  2. Do NOT invent a desktop layout — implement mobile as designed
- If Figma contains **both desktop and mobile frames**:
  1. Map each frame to the appropriate breakpoint
  2. Interpolate intermediate sizes using the framework's grid system

### Layout Translation
- Figma Auto Layout (horizontal) → CSS `flex-direction: row` (stack to column on mobile)
- Figma Auto Layout (vertical) → CSS `flex-direction: column`
- Figma fixed width containers → use `max-width` + responsive padding
- Figma percentage-like proportions → use grid columns or flex ratios

### Proportion Check
- If an element's width is between 60%–90% of its parent (not full-width, not clearly a sidebar), **ask the user** about the intended responsive behavior rather than guessing
- Apply standard framework breakpoints for responsive behavior even if Figma doesn't explicitly specify them
- Use Tailwind breakpoint prefixes: `sm:`, `md:`, `lg:`, `xl:`, `2xl:`

## Component Strategy: Component First

Extract repeated patterns into reusable components.

- If a **similar structure appears 2 or more times**, extract it into a reusable component
- Component detection criteria: same layout structure + same style pattern (colors, spacing, typography may vary as props)
- Use Figma component/variant names as the **starting point** for component naming, then adapt to framework conventions

### Naming Conventions
- PascalCase for component names: `ProductCard`, `NavBar`, `HeroSection`
- Props interface in the same file or co-located `.types.ts`
- File structure: `components/ProductCard/ProductCard.tsx` + `index.ts` barrel export

### Variant Mapping
- Figma component variants → component props (e.g. Figma `size=large` → prop `size="lg"`)
- Figma boolean properties → boolean props
- Figma instance swaps → slot/children patterns

## CSS Variables & Design Tokens

In balanced mode, map Figma values to existing project tokens where possible.

- If the project defines CSS variables / design tokens, always prefer them over raw values
- If a Figma value has no corresponding token, use the raw value but add a comment: `/* TODO: no matching token */`
- If Figma uses Figma Variables, map them 1:1 to CSS custom properties:
  - Figma `color/primary` → `var(--color-primary)`
  - Figma `spacing/md` → `var(--spacing-md)`

### Tailwind Integration
- Map Figma tokens to `tailwind.config` theme extensions when possible
- Prefer Tailwind utility classes over inline styles or custom CSS
- For values not in the default Tailwind scale, use arbitrary values `[13px]` in pixel-perfect mode, or extend the config in balanced/reference mode

## Spacing Strategy

- Convert Figma px values to the framework's spacing scale
  - 4px → 0.25rem, 8px → 0.5rem, 12px → 0.75rem, 16px → 1rem, 24px → 1.5rem, 32px → 2rem
- Snap to the framework's spacing scale when possible
- Font sizes in rem, line-heights as unitless ratios
- Use Tailwind spacing utilities: `p-4` (1rem), `m-2` (0.5rem), `gap-3` (0.75rem)
- For non-standard values in balanced/reference mode, extend `tailwind.config` rather than using arbitrary values

## State Handling (Hover, Active, Disabled, Loading)

### Figma Variants → Interactive States
- If Figma defines explicit variants for states (hover, pressed, disabled, focused, loading), implement them exactly
- Map Figma variant properties to CSS pseudo-classes and state classes:
  - Figma `state=hover` → `:hover`
  - Figma `state=pressed` / `state=active` → `:active`
  - Figma `state=disabled` → `:disabled` or `[aria-disabled="true"]`
  - Figma `state=focused` → `:focus-visible`
  - Figma `state=loading` → conditional render with loading indicator

### Missing States
- For **interactive elements** (buttons, links, inputs, toggles) that lack explicit state designs:
  - Add standard hover: slight opacity change or background shift using existing tokens
  - Add standard active/pressed: darker shade or scale(0.98) transform
  - Add standard disabled: opacity 0.5 + cursor not-allowed
  - Add standard focus-visible: 2px outline using the primary color token
- For **non-interactive elements**: do NOT add states unless Figma specifies them
- If unsure whether an element should be interactive, **ask the user**

### Transitions
- Add `transition` for hover/active state changes (150-200ms ease)
- Do NOT add transitions for disabled states
- Loading states should use the project's standard loading pattern (spinner, skeleton, etc.)

## Accessibility (a11y)

### Semantic HTML
- Use semantic HTML elements based on visual and functional role:
  - Navigation bar → `<nav>`
  - Main content area → `<main>`
  - Grouped sections → `<section>` with `aria-labelledby`
  - Page header/footer → `<header>` / `<footer>`
  - Lists → `<ul>`/`<ol>` (not divs with list-like styling)
  - Headings → proper `<h1>`–`<h6>` hierarchy (no skipping levels)
- Buttons that look like links should still be `<button>` if they perform actions
- Links that navigate should be `<a href>`

### ARIA & Labels
- All images must have `alt` text (derive from Figma layer names or content context)
- Decorative images/icons → `alt=""` + `aria-hidden="true"`
- Icon-only buttons → must have `aria-label`
- Form inputs → must have associated `<label>` or `aria-label`
- Interactive components (modals, tabs, accordions) → use appropriate ARIA roles and patterns

### Color Contrast
- Implement colors as designed in Figma
- If you notice an obvious contrast issue (e.g. light gray text on white), add a comment: `/* ⚠ potential contrast issue — verify */`

### Keyboard Navigation
- All interactive elements must be reachable via Tab key
- Focus order should follow visual layout (top-to-bottom, left-to-right)
- `:focus-visible` styles must be visible — never set `outline: none` without a replacement

## CSS Framework: Tailwind CSS

- Use Tailwind utility classes for all styling — avoid inline `style` attributes
- Conditional classes via `clsx`, `cn()`, or template literals
- Use `className` in JSX frameworks, `class` in Vue/Svelte/HTML
- Responsive: `sm:`, `md:`, `lg:`, `xl:`, `2xl:` prefixes
- Dark mode: `dark:` prefix if project supports it
- For values not in Tailwind's default scale, use arbitrary values `[13px]` or extend `tailwind.config`
- SVG icons: inline as components or use the project's icon system

## Frontend Framework: Next.js

- Default to **Server Components** — only add `'use client'` when the component needs:
  - Event handlers (onClick, onChange, etc.)
  - React hooks (useState, useEffect, etc.)
  - Browser-only APIs (window, localStorage)
- Use `next/image` for all images (auto-optimization, lazy loading)
- Use `next/link` for internal navigation
- Use `next/font` for font loading — do NOT add `<link>` tags for Google Fonts
- Metadata: use `export const metadata` in layouts/pages, not `<Head>`
- File structure follows App Router conventions: `app/` directory with `page.tsx`, `layout.tsx`

## Asset Handling

- If Figma MCP returns a localhost source for an image/SVG, use that source directly
- Do NOT import new icon packages — all assets come from the Figma payload
- Do NOT create placeholders when a localhost source is provided
- SVG icons: prefer inline SVG for styling flexibility, or use the project's icon component system

## Code Connect

- Use `get_code_connect_map` to discover existing Figma-to-code component mappings
- When implementing a Figma component that has a Code Connect entry, **always use the mapped component**
- After creating a new component, register it with `add_code_connect_map` so future implementations can reuse it
- Code Connect mappings take priority over all other rules — if a mapping exists, use it as-is

## SVG Fallback (when MCP is unavailable or rate-limited)

When the Figma MCP server returns a rate limit error (429) or is otherwise unavailable, guide the user to provide design data manually via SVG.

### How to trigger this fallback
If an MCP tool call fails with a rate limit or connection error:
1. Tell the user: "Figma API rate limit reached. You can copy the SVG from Figma so I can continue working."
2. Provide these steps:
   - In Figma, select the target frame/component
   - Right-click → Copy/Paste as → Copy as SVG (or Cmd/Ctrl+Shift+C)
   - Paste the SVG into this chat
3. Once the user provides the SVG, proceed with the implementation using the rules below

### Reading design intent from SVG
SVG contains structured layout information that can be used to infer the original design:

**Layout & Structure**
- `<g>` groups with transform → section/container boundaries
- Nested `<g>` hierarchy → component nesting structure
- `<rect>` with fill → background containers, cards, buttons
- `<text>` elements → typography (font-family, font-size, font-weight, fill color)
- Element ordering (top to bottom in SVG) → visual stacking order (back to front)

**Dimensions & Spacing**
- `width` / `height` attributes → element sizing
- `x` / `y` attributes → absolute positioning (convert to relative spacing by calculating gaps between siblings)
- `rx` / `ry` on `<rect>` → border-radius
- Gap between sibling elements = next element's y - (current element's y + current element's height)

**Colors & Styles**
- `fill` attribute → background-color or text color
- `stroke` + `stroke-width` → border
- `opacity` → opacity
- Linear/radial `<gradient>` definitions → CSS gradients
- `filter` with `feDropShadow` or `feGaussianBlur` → box-shadow

**Typography**
- `<text font-family="..." font-size="..." font-weight="..." fill="...">` → all typography properties
- `letter-spacing` attribute → letter-spacing
- `text-anchor` → text-align (start=left, middle=center, end=right)

**Images & Icons**
- `<image href="...">` → image elements (href may be base64 or blob — ask user for actual asset)
- Small `<svg>` groups with paths → icons (keep as inline SVG)
- `<clipPath>` regions → overflow hidden / rounded containers

### SVG → Code translation
- Use SVG dimensions as reference, but snap to project design tokens where they exist
- Map SVG fill colors to the nearest design token
- Convert SVG dimensions to Tailwind utilities (e.g., width="384" → w-96, gap of 16px → gap-4)
- Convert absolute x/y positioning to flexbox/grid layouts
- Group visually adjacent elements into flex containers based on alignment patterns:
  - Elements sharing the same `y` value → horizontal flex row
  - Elements sharing the same `x` value → vertical flex column
- Do NOT output raw SVG markup as the final code — always convert to semantic HTML + CSS

### Differences from MCP — what SVG cannot provide
Inform the user that SVG fallback is an approximation, not a replacement for MCP. Key gaps:

| Capability | Figma MCP | SVG Fallback |
|---|---|---|
| Auto Layout direction & gap | Exact values from API | Approximated from x/y positions — may be off by a few px |
| Component variants (hover, active, disabled) | All variants accessible | Only the currently visible variant — ask user to copy each state separately |
| Figma Variables & design tokens | Direct access via `get_variable_defs` | Not available — must rely on project's existing tokens |
| Responsive constraints | Fill/Hug/Fixed info from API | Not present in SVG — must discuss with user |
| Layer names & semantic structure | Preserved from Figma | Partially preserved (Figma exports some layer names as `id` attributes, but not all) |
| Nested component instances | Detected and resolved by MCP | Flattened in SVG — nested components become raw shapes |
| Text content overflow / truncation | API provides full text + overflow settings | SVG only shows visible text — truncated text is lost |
| Image assets | Downloadable via MCP endpoint | Embedded as base64 or missing — user may need to export separately |
| Figma Styles (shared colors, text styles) | Linked to style definitions | Inlined as raw values — no connection to shared styles |
| Design system search | Available via Official MCP | Not available |

When using SVG fallback, always tell the user:
> "I'm working from the SVG copy, which gives me layout and visual information but lacks some Figma-specific data like Auto Layout settings, component variants, and design tokens. The result may need minor adjustments. If accuracy is critical, try again with MCP when the rate limit resets."
