<script>
    import { onMount, onDestroy } from "svelte";
    import { isRunning, pipelineStatus, thumbnails } from "./store.js";
    import PipelineButton from "./PipelineButton.svelte";
    import { API_ENDPOINTS } from "./constants.js";

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
        $isRunning = true;
        appendPipelineStatus(null, "Generating PDF...");

        const fileList = $thumbnails.map((thumbnail) =>
            thumbnail.name.substring(0, thumbnail.name.lastIndexOf(".")),
        );

        try {
            const response = await fetch(API_ENDPOINTS.GENERATE_PDF, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({ files: fileList }),
            });

            if (response.ok) {
                appendPipelineStatus(null, "PDF generated successfully");
            } else {
                throw new Error("Failed to generate PDF");
            }
        } catch (error) {
            appendPipelineStatus(null, `Error generating PDF: ${error}`);
        } finally {
            $isRunning = false;
        }
    }
</script>

<PipelineButton text="Scan" on:click={startScan} />
<PipelineButton text="PDF" on:click={generatePDF} />
