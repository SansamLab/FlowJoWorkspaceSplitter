[![](https://img.shields.io/badge/Shiny-shinyapps.io-blue?style=flat&labelColor=white&logo=RStudio&logoColor=blue)](https://sansamlab.shinyapps.io/SplitFlowJoFile/)
![Release](https://img.shields.io/github/v/release/SansamLab/FlowJoWorkspaceSplitter)
![ReleaseDate](https://img.shields.io/github/release-date/SansamLab/FlowJoWorkspaceSplitter)
![Size](https://img.shields.io/github/repo-size/SansamLab/FlowJoWorkspaceSplitter)
![License](https://img.shields.io/github/license/SansamLab/FlowJoWorkspaceSplitter)
![LastCommit](https://img.shields.io/github/last-commit/SansamLab/FlowJoWorkspaceSplitter)
![Downloads](https://img.shields.io/github/downloads/SansamLab/FlowJoWorkspaceSplitter/total)
![OpenIssues](https://img.shields.io/github/issues-raw/SansamLab/FlowJoWorkspaceSplitter)



# FlowJo Workspace Splitter

## Overview

FlowJo Workspace Splitter is a Shiny application designed to help researchers split FlowJo workspace (`.wsp`) files into individual workspace files for each sample. This makes it easier to organize files for depositing on repositories, as FlowJo workspaces often contain additional samples and metadata that researchers may not wish to include.

The application processes `.wsp` files, which are XML-based, and modifies them so that each output file contains only a single sample. It also removes unnecessary elements such as tables and layouts to simplify the workspace.

## How It Works

1. Upload a `.wsp` file containing multiple samples.
2. The app processes the XML file, keeping only one sample per output workspace.
3. It removes:
   - Unnecessary elements such as tables, layouts, and scripts.
   - Full file paths from `uri` attributes, leaving only the `.fcs` file names. Note that this means that the .wsp file will look for the .fcs file in its own directory.
4. The processed files are packaged into a zip archive for download.

## Warning

The functionality of this app **depends on the FlowJo XML file structure remaining the same**.  
It was developed and tested with **FlowJo version 10.9.0**.  
If FlowJo updates its workspace format, modifications to this app may be required.

## Running the App in RStudio

To install and run the FlowJo Workspace Splitter app directly from RStudio:

```r
# Install required packages if not already installed
install.packages(c("shiny", "xml2", "magrittr", "fs"))

# Clone the repository and run the app
shiny::runGitHub("FlowJoWorkspaceSplitter", "SansamLab")
