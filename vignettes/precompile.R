# Precompile Quarto vignette with API outputs
# Simple approach: execute original, embed outputs, add eval: false

library(knitr)
library(rmarkdown)

# Step 1: Render the original vignette to markdown format to capture all outputs
rmarkdown::render("vignettes/cnbrrr-orig.qmd",
                  output_format = "github_document",
                  output_file = "temp-with-outputs.md")

# Step 2: Read the original QMD structure and the executed markdown
original_content <- readLines("vignettes/cnbrrr-orig.qmd")
executed_content <- readLines("vignettes/temp-with-outputs.md")

# Step 3: Create the precompiled version
# Start with original content and modify chunks
precompiled <- original_content

# Add eval: false to all R chunks that don't already have it
i <- 1
while (i <= length(precompiled)) {
  line <- precompiled[i]

  if (grepl("^```\\{r", line)) {
    # Check if eval: false already exists in this chunk
    has_eval_false <- grepl("eval.*=.*F", line)

    if (!has_eval_false) {
      # Look ahead a few lines to see if eval: false exists
      look_ahead <- min(i + 5, length(precompiled))
      for (j in (i+1):look_ahead) {
        if (grepl("^```", precompiled[j]) && j > i) break
        if (grepl("#\\|.*eval.*false", precompiled[j])) {
          has_eval_false <- TRUE
          break
        }
      }
    }

    # If no eval: false found, add it
    if (!has_eval_false) {
      precompiled <- append(precompiled, "#| eval: false", after = i)
      i <- i + 1  # Skip the line we just added
    }
  }
  i <- i + 1
}

# Step 4: Now we need to extract and embed the outputs
# For this simpler version, we'll create a separate process to get outputs

# Use knitr to create a version with embedded outputs
temp_file <- "temp-for-outputs.qmd"
writeLines(original_content, temp_file)

# Knit to get outputs
knitr::knit(temp_file, output = "temp-knitted.md")
knitted_content <- readLines("temp-knitted.md")

# Step 5: Parse the knitted content to extract outputs by chunk
chunk_outputs <- list()
current_chunk <- 0
in_output <- FALSE
current_output <- c()

for (line in knitted_content) {
  if (grepl("^``` r", line)) {
    current_chunk <- current_chunk + 1
    in_output <- FALSE
  } else if (grepl("^```$", line) && current_chunk > 0) {
    in_output <- TRUE
  } else if (in_output && (grepl("^#+", line) || grepl("^``` r", line))) {
    # End of output section
    if (length(current_output) > 0) {
      chunk_outputs[[current_chunk]] <- current_output
      current_output <- c()
    }
    in_output <- FALSE
    if (grepl("^``` r", line)) {
      current_chunk <- current_chunk + 1
    }
  } else if (in_output) {
    current_output <- c(current_output, line)
  }
}

# Capture any remaining output
if (length(current_output) > 0 && current_chunk > 0) {
  chunk_outputs[[current_chunk]] <- current_output
}

# Step 6: Insert outputs into the precompiled version
final_content <- c()
chunk_num <- 0

i <- 1
while (i <= length(precompiled)) {
  line <- precompiled[i]
  final_content <- c(final_content, line)

  if (grepl("^```\\{r", line)) {
    chunk_num <- chunk_num + 1
    i <- i + 1

    # Copy chunk options and code
    while (i <= length(precompiled) && !grepl("^```$", precompiled[i])) {
      final_content <- c(final_content, precompiled[i])
      i <- i + 1
    }

    # Add the chunk outputs if they exist
    if (chunk_num <= length(chunk_outputs) && length(chunk_outputs[[chunk_num]]) > 0) {
      final_content <- c(final_content, chunk_outputs[[chunk_num]])
    }

    # Add closing ```
    if (i <= length(precompiled)) {
      final_content <- c(final_content, precompiled[i])
    }
  }
  i <- i + 1
}

# Step 7: Write the final precompiled vignette
writeLines(final_content, "vignettes/cnbrrr.qmd")

# Step 8: Clean up temporary files
file.remove("vignettes/temp-with-outputs.md")
file.remove("vignettes/temp-with-outputs.html")
file.remove(temp_file)
file.remove("temp-knitted.md")

# Copy any figure directories
if (dir.exists("temp-for-outputs_files")) {
  if (dir.exists("vignettes/cnbrrr_files")) {
    unlink("vignettes/cnbrrr_files", recursive = TRUE)
  }
  file.copy("temp-for-outputs_files", "vignettes/cnbrrr_files", recursive = TRUE)
  unlink("temp-for-outputs_files", recursive = TRUE)
}

cat("Precompiled vignette created successfully!\n")
cat("- Original: vignettes/cnbrrr-orig.qmd\n")
cat("- Precompiled: vignettes/cnbrrr.qmd (with embedded outputs)\n")
cat("- All code chunks set to eval=false to prevent re-execution during build\n")
cat("- Outputs preserved and embedded in the vignette\n")
