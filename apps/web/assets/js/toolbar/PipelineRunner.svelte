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

    export let show = "scan";

    let scanConfigs = [];

    onMount(async () => {
        if (show === "scan") {
            // Only fetch scan config if showing scan buttons
            try {
                const response = await fetch(API_ENDPOINTS.SCAN_CONFIG);
                if (response.ok) {
                    scanConfigs = await response.json();
                } else {
                    console.error("Failed to fetch scan config");
                }
            } catch (error) {
                console.error("Error fetching scan config:", error);
            }
        }
    });

    function appendPipelineStatus(executionId, message) {
        $pipelineStatus = [...$pipelineStatus, { message }];
    }

    async function startScan(pipelineId) {
        $isRunning = true;
        appendPipelineStatus(null, `Starting ${pipelineId} pipeline...`);

        try {
            await fetch(API_ENDPOINTS.SCAN_PIPELINE, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({ pipeline: pipelineId }),
            });
        } catch (error) {
            appendPipelineStatus(
                null,
                `Error starting ${pipelineId} pipeline: ${error}`,
            );
            $isRunning = false;
        }
    }

    async function generatePDF() {
        appendPipelineStatus(null, "Generating PDF...");
        $documents.forEach(async (document) => {
            const fileList = document.map((page) => page.name);
            try {
                const response = await fetch(API_ENDPOINTS.EXPORT_DOCUMENT, {
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

{#if show === "scan"}
    {#each scanConfigs as config}
        <PipelineButton
            text={config.label}
            on:click={() => startScan(config.id)}
        />
    {/each}
{:else if show === "export"}
    <PipelineButton text="Export PDF" on:click={generatePDF} />
{/if}
