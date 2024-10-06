<script>
    import { onMount, onDestroy } from "svelte";
    import {
        isRunning,
        pipelineStatus,
        thumbnails,
        documents,
    } from "../store.js";
    import PipelineButton from "./PipelineButton.svelte";
    import { API_ENDPOINTS } from "../constants.js";

    function appendPipelineStatus(executionId, message) {
        $pipelineStatus = [...$pipelineStatus, { message }];
    }

    async function startScan() {
        $isRunning = true;
        appendPipelineStatus(null, "Starting pipeline...");

        try {
            await fetch(API_ENDPOINTS.SCAN_PIPELINE, { method: "POST" });
        } catch (error) {
            appendPipelineStatus(null, `Error starting pipeline: ${error}`);
            $isRunning = false;
        }
    }

    async function generatePDF() {
        appendPipelineStatus(null, "Generating PDF...");
        $documents.forEach(async (document) => {
            const fileList = document.map((page) => page.name);
            try {
                const response = await fetch(API_ENDPOINTS.GENERATE_PDF, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({ pages: fileList }),
                });

                if (response.ok) {
                    appendPipelineStatus(null, "PDF generated successfully");
                } else {
                    throw new Error("Failed to generate PDF");
                }
            } catch (error) {
                appendPipelineStatus(null, `Error generating PDF: ${error}`);
            } finally {
            }
        });
    }
</script>

<PipelineButton text="Scan" on:click={startScan} />
<PipelineButton text="PDF" on:click={generatePDF} />
