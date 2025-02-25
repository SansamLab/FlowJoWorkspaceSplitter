library(shiny)
library(xml2)
library(magrittr)
library(fs)

ui <- fluidPage(
  titlePanel("FlowJo Workspace Splitter"),
  sidebarLayout(
    sidebarPanel(
      fileInput("wspFile", "Upload FlowJo Workspace (.wsp) file", 
                accept = c(".wsp")),
      actionButton("process", "Process File"),
      downloadButton("downloadZip", "Download Modified Workspaces")
    ),
    mainPanel(
      verbatimTextOutput("status")
    )
  )
)

server <- function(input, output, session) {
  
  # Reactive value to store the path to the zip file
  processedZip <- reactiveVal(NULL)
  
  observeEvent(input$process, {
    req(input$wspFile)
    
    # Use the uploaded file's temporary path.
    inFile <- input$wspFile$datapath
    
    # Create a temporary output directory.
    outputDir <- file.path(tempdir(), "modified_wsp")
    if (!dir.exists(outputDir)) {
      dir.create(outputDir)
    }
    
    # Read the original workspace XML.
    doc_orig <- read_xml(inFile)
    
    # Remove unnecessary nodes.
    nodesToRemove <- c("TableEditor", "LayoutEditor", "Scripts", "WindowPosition",
                       "TextTraits", "Columns", "Matrices", "Exports", "SOPS", 
                       "weights", "experiment", "Experiment")
    for (nodeName in nodesToRemove) {
      node <- xml_find_first(doc_orig, paste0("./", nodeName))
      if (!is.na(xml_name(node))) {
        xml_remove(node)
      }
    }
    
    # Find all DataSet nodes.
    dataSet_nodes <- xml_find_all(doc_orig, "//DataSet")
    nNodes <- length(dataSet_nodes)
    
    if(nNodes == 0) {
      output$status <- renderPrint("No DataSet nodes found in the workspace.")
      return()
    }
    
    # Process each DataSet node.
    for (ds in dataSet_nodes) {
      # Extract sampleID and uri attributes.
      sample_id <- xml_attr(ds, "sampleID")
      uri <- xml_attr(ds, "uri")
      
      # Remove the "file:" prefix and decode %20 as spaces.
      uri_trimmed <- sub("^file:", "", uri) %>% gsub("%20", " ", .)
      file_base <- basename(uri_trimmed)
      # file_base_no_ext is used for naming the output file
      file_base_no_ext <- sub("\\.fcs$", "", file_base, ignore.case = TRUE) %>% 
        sub("%20", " ", .)
      
      cat("Processing sampleID:", sample_id, "with file base:", file_base_no_ext, "\n")
      
      # Reload a fresh copy of the original workspace.
      doc <- read_xml(inFile)
      for (nodeName in nodesToRemove) {
        node <- xml_find_first(doc, paste0("./", nodeName))
        if (!is.na(xml_name(node))) {
          xml_remove(node)
        }
      }
      
      # Remove all nodes with a sampleID attribute not equal to the current one.
      xpath_query <- sprintf("//*[@sampleID and not(@sampleID='%s')]", sample_id)
      nodes_to_remove <- xml_find_all(doc, xpath_query)
      for (node in nodes_to_remove) {
        xml_remove(node)
      }
      
      # Now update the "uri" attribute for the remaining DataSet node(s) so that it only contains the file name.
      remaining_nodes <- xml_find_all(doc, sprintf("//*[@sampleID='%s']", sample_id))
      for (node in remaining_nodes) {
        xml_set_attr(node, "uri", file_base)
      }
      
      # Save the modified workspace using the .fcs base (without extension) as the file name.
      out_file <- file.path(outputDir, sprintf("%s.wsp", file_base_no_ext))
      write_xml(doc, out_file)
    }
    
    # Zip only the .wsp files without including subfolders.
    zipFile <- file.path(outputDir, "modified_workspaces.zip")
    old_wd <- getwd()
    setwd(outputDir)
    wsp_files <- list.files(pattern = "\\.wsp$", recursive = FALSE, full.names = FALSE)
    zip(zipfile = "modified_workspaces.zip", files = wsp_files)
    setwd(old_wd)
    
    processedZip(zipFile)
    
    output$status <- renderPrint({
      cat("Processed", nNodes, "DataSet nodes.\n")
      cat("Modified workspace files are saved in:\n", outputDir, "\n")
      cat("Zip file created at:\n", zipFile, "\n")
    })
  })
  
  # Download handler: when the user clicks download, the zip file is sent to the browser.
  output$downloadZip <- downloadHandler(
    filename = function() {
      "modified_workspaces.zip"
    },
    content = function(file) {
      req(processedZip())
      file.copy(processedZip(), file)
    }
  )
}

shinyApp(ui, server)
