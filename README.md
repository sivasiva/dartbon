# Bourbon (Dart Sass port)

Dart Sass-native port of **Bourbon 4.3.4** — the full public API of mixins and
functions, converted to the module system (`@use`/`@forward`) and compiling with
zero deprecation warnings under Dart Sass. Bourbon's internal self-deprecation
warnings have been removed.

## Consuming in a host application

This package is a **drop-in replacement** for a vendored Bourbon 4.x. It is plain
SCSS with no build step of its own — your host app compiles it with its own Dart
Sass (dartsass-rails, dartsass-sprockets, cssbundling-rails, or the `sass` CLI).

### 1. Add the files

Copy this repo into your app so that `_bourbon.scss` sits at the top of a
`bourbon/` folder, e.g.:

```
app/assets/stylesheets/vendor/bourbon/
├── _bourbon.scss
├── settings/  functions/  helpers/  css3/  addons/
└── ...
```

Only the `.scss` files and their folders are needed at runtime. `node_modules/`,
`test/`, `bin/`, and `package.json` are dev-only and can be omitted from the
vendored copy.

### 2. Put the folder on the Dart Sass load path

Dart Sass resolves imports against its **load paths**. With **dartsass-rails /
dartsass-sprockets**, `app/assets/stylesheets` and every `config.assets.paths`
entry are load paths automatically, so:

- **Out of the box**, import with the path relative to `app/assets/stylesheets`:

  ```scss
  @use "vendor/bourbon/bourbon" as *;
  ```

- **To use the shorter `bourbon/bourbon`**, add the vendor dir as a load-path
  root in `config/initializers/assets.rb`:

  ```ruby
  Rails.application.config.assets.paths << Rails.root.join("app/assets/stylesheets/vendor")
  ```

  If you were already consuming the old Bourbon as `@import "bourbon/bourbon"`,
  this is **already configured** — just swap the files in place, nothing else to do.

For a plain `sass` CLI (or other build), pass the folder that *contains*
`bourbon/` via `--load-path`:

```bash
sass --load-path=app/assets/stylesheets/vendor input.scss output.css
```

### 3. Import it in your stylesheets

**Modern — fully warning-free (recommended):**

```scss
@use "bourbon/bourbon" as *;

.button { @include size(10px); }
```

Use the explicit `bourbon/bourbon` path, not the bare directory `bourbon`.
`@use` of a bare directory needs a `bourbon/_index.scss`, which this package
does not ship — `@use "bourbon" as *;` fails with
`Error: Can't find stylesheet to import.`

**Legacy — `@import` (unchanged from Bourbon 4.x, no call-site edits):**

```scss
@import "bourbon/bourbon";

.button { @include size(10px); }
```

`@import "bourbon/bourbon"` still exposes the whole API globally. Dart Sass emits
a single `@import is deprecated` warning for *this one consumer line* — the
library's own internals are `@import`-free. To silence it, switch that line to
`@use "bourbon/bourbon" as *;`.

### 4. Build

Run your usual asset build (e.g. `bin/rails dartsass:build`, or it happens
automatically in `dev`). Via the `@use` path it compiles with **zero deprecation
warnings**.

## Settings

Bourbon settings (e.g. `$em-base`, prefixer flags) are module `!default`
variables.

With legacy `@import "bourbon/bourbon"`, defining a Bourbon setting variable
*before* the import still overrides it — Dart Sass configures modules through
imports, so this keeps working exactly as it did with Ruby Sass:

```scss
$em-base: 20px;
@import "bourbon/bourbon";

.x { font-size: em(10px); } // => 0.5em (default is 0.625em, i.e. 10px / 16px)
```

With `@use "bourbon/bourbon" as *`, configure the module explicitly instead,
using the same `with (...)` clause:

```scss
@use "bourbon/bourbon" as * with ($em-base: 20px);

.x { font-size: em(10px); } // => 0.5em
```

## Development

```bash
npm install
npm test   # compiles fixtures, asserts zero deprecation warnings + golden output
```
