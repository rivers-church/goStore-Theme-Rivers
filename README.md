# Rivers Church theme for gostore

Makes the store look like [rivers.church](https://rivers.church): the RIVERS
wordmark and R favicons, Helvetica Neue LT Pro from the church's Adobe Fonts kit,
black / white / whitesmoke, the site's rounded black buttons, its footer, and
product cards shaped like the home page's event cards.

## What is overridden

| File | Why |
|---|---|
| `static/styles.css` | The whole look. Copied from gostore's default and edited; the brand values are the `:root` block at the top |
| `templates/partials/document.gohtml` | Favicons. Otherwise the default verbatim, htmx settings included |
| `templates/layouts/public.gohtml` | Header (wordmark, nav, Cart button) and the rivers.church-style footer |
| `templates/partials/product_grid.gohtml` | Event-style product cards, on both the index and the catalog |
| `static/*.png`, `rivers-logo.webp`, `instagram.svg` | Brand assets, taken from rivers.church |

The admin keeps gostore's own layout, so it gets the colours and buttons but not
the wordmark.

Each copied file stops receiving upstream fixes. When upgrading gostore, diff
these against `internal/handler/templates/` and `internal/handler/static/styles.css`.

## Product images

Cards use one 16:9 frame, like the event cards, so a grid mixing books and
conferences still lines up. Images are fitted inside it, never cropped: a 16:9
conference thumbnail fills it, and a book cover shows whole with whitesmoke bars
at the sides. For the cleanest cards, export every product image at 16:9 (a book
cover on a 16:9 background). On the product page itself, an image keeps its own
shape, capped at 80% of the screen height. `--card-ratio` in `styles.css` changes
the card frame.

## The font

Helvetica Neue LT Pro is served by Adobe Fonts kit `voh5omd`, the same kit
rivers.church uses. Adobe's licence does not allow self-hosting, so the server
needs both of these (in gostore's `.env` for development, or the deployment's
environment):

```sh
FONT_ORIGINS=https://use.typekit.net,https://p.typekit.net
FONT_CSS_URL=https://use.typekit.net/voh5omd.css
```

Without them the stylesheet falls back to the system's Helvetica Neue / Helvetica /
Arial. Adobe kits are locked to a list of domains, so add the store's production
domain to the kit's web project in Adobe Fonts, or the font will not load there.

---

# theme/

Your theme. The compose stack mounts this directory into the server and sets
`TEMPLATE_DIR=/theme/templates` and `STATIC_DIR=/theme/static`, with
`THEME_RELOAD=true` — so a file dropped in here takes effect on the next page
refresh, with no restart and no rebuild.

- `templates/` — shaped like
  [`internal/handler/templates/`](../internal/handler/templates): `layouts/`,
  `partials/`, `pages/`, `admin/`, `mail/`. A file at the **same path** as an
  embedded default replaces the definitions in it; every other definition, and
  every other file, keeps falling back. The path is the contract, so a
  `products.gohtml` at the top of this directory is a file nothing looks for.
- `static/` — assets by name, flat. A `styles.css` here shadows the bundled one; a
  `logo.svg` here rebrands the header. New names are served too, so an overridden
  template can reference its own `hero.png`.

Each page is parsed into a template set of its own — the shared partials, its
layout, then the page file. That is what lets a `pages/products.gohtml` here fill
the layout's `nav_extra` block on the catalog and nowhere else. It also means a
page can only call a partial, its own layout, or something it defines itself:
anything two pages need belongs in `partials/`.

Both directories start empty, which means the store looks exactly as it does with
no theme at all. Copy a default out of
[`internal/handler/templates/`](../internal/handler/templates) or
[`internal/handler/static/`](../internal/handler/static) — keeping its
subdirectory — and edit the copy.

Copy only what you are actually changing. A copied file that is not being changed
is a copy that silently stops receiving fixes: it goes on rendering the version of
that page you took, and a later release that corrects it changes nothing for you.

Nothing in here is used unless `TEMPLATE_DIR` / `STATIC_DIR` point at it, so this
directory is safe to leave empty, delete the contents of, or keep in a branch of
your own. See [Theming](../docs/theming.md).
