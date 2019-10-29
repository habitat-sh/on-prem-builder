# Chef Habitat Builder on-prem  - Website

A new static website for Chef Habitat on-prem is based on [Hugo](https://gohugo.io), the Go-powered static site generator.

## Getting Started

### Install Hugo for MacOS or Windows

1. Disable smart quotes. OS X tries to use smartquotes by default when editing Hugo docs. You want smartquotes disabled regardless if you are writing code. Here's how [you can disable it](http://www.iclarified.com/38772/how-to-disable-curly-quotes-in-mac-os-x-mavericks).

1. [Install Hugo](https://gohugo.io/getting-started/installing/).

If you're using homebrew on MacOS or Linuxbrew on Linux:

    ```
    brew install hugo
    ```

If you're using Chocolatey on Windows:

    ```powershell
    choco install hugo -confirm
    ```

For the "extended" Sass/SCSS:

    ```powershell
    choco install hugo-extended -confirm
    ```

If you're using Scoop on Windows:

    ```powershell
    scoop install hugo
    ```

For downloading and installing for other OS's or by other methods, see the [Hugo installation documentation](https://gohugo.io/getting-started/installing/)

### Setup Theme Submodules

This site uses git submodules for the site theme. To access the theme, initialize your local configuration file and update to the most recent version of the theme with:

```
git submodule init && git submodule update
```

### View the docs

From the `on-prem-docs` directory, run `hugo server` to serve the docs.
Use `hugo server -D` to serve the docs with draft content

### Development

1. From the `on-prem-docs` directory, run the following command to start the development server.

    ```
    $ make serve
    ```

    When this is running, any changes you make to content in the `components/automate-chef-io` directory will be automatically compiled and updated the browser.

## Creating Docs and Making Changes

The site is built with [Hugo](https://gohugo.io/), a Go-based static site generator, and uses [Stencil](https://stenciljs.com/) for web components and [Sass](http://sass-lang.com/) for CSS. You'll probably want to familiarize yourself with the Hugo documentation, which covers templating, layouts, functions, etc., but there are helpers to assist you with doing some common things, like creating a new docs page:

```shell
hugo new docs/my-sweet-new-post.md
```

Your new post will be created as a draft with enough [frontmatter](https://gohugo.io/content-management/front-matter/) to get you going. All content is authored in [Markdown](https://en.wikipedia.org/wiki/Markdown).

## Helpers

make sync
: Pull down the current chef hugo theme

make serve
: Start the live-reload development environment

> If you get a `git clone` related failure when running these commands, you may not have your HTTPS GitHub credentials setup. These commands will clone down the hugo theme via HTTPS. [Read these docs](https://help.github.com/articles/which-remote-url-should-i-use/#cloning-with-https-urls-recommended) to learn why we use HTTPS over SSH, and how to setup your GitHub credentials.

## Markdown Content

Please try to keep all your documentation in the `docs` directory. Any new documents should automatically show up in the sidebar. If you need to control the ordering of the sidebar, you can add `weight` to the frontmatter of the documents.

To add a new Markdown file, simply run the following command from the `on-prem-bulder\on-prem-docs` directory:

```
hugo new docs/<filename>.md
```

This will create the file in the `content/docs` directory and fill in the minimum necessary frontmatter automatically.

## Data Content

Hugo allows us to nest our data directory structure as much as necessary. You can add as many folders as necessary under `components/automate-chef-io/data/docs`.

```
.
├── data
│   ├── docs
│   │   ├── cli
|   │   │   ├── command_one.yml
|   │   │   └── command_two.yml
```
