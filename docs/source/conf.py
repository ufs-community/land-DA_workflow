# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = "UFS Offline Land DA User's Guide"
copyright = '2023, '
author = ' '

# The short X.Y version
version = 'v1.2'
# The full version, including alpha/beta/rc tags
release = 'v1.2.0'

numfig = True

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx_rtd_theme',
    'sphinx.ext.intersphinx',
    'sphinxcontrib.bibtex',
]

# File with bibliographic info
bibtex_bibfiles = ['references.bib']

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# The master toctree document.
master_doc = 'index'

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

# Documentation-wide substitutions

rst_prolog = """
.. |latestr| replace:: v1.2.0
"""

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'sphinx_rtd_theme'
html_theme_path = ["_themes", ]

# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
#
html_theme_options = {
    "body_max_width": "none", 
    'navigation_depth': 6,
    }

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']
html_context = {}

def setup(app):
    app.add_css_file('custom.css')  # may also be an URL
    app.add_css_file('theme_overrides.css')  # may also be a URL

# Example configuration for intersphinx: refer to the Python standard library.
intersphinx_mapping = {
   'jedi': ('https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/1.7.0', None),
   'spack-stack': ('https://spack-stack.readthedocs.io/en/1.3.0/', None),
   'ufs-wm': ('https://ufs-weather-model.readthedocs.io/en/latest/', None),
   'gswp3': ('https://hydro.iis.u-tokyo.ac.jp/GSWP3/', None),
}
