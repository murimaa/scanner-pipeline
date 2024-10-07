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
    let exportConfigs = [];

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
        if (show === "export") {
            // Only fetch export config if showing export buttons
            try {
                const response = await fetch(API_ENDPOINTS.EXPORT_CONFIG);
                if (response.ok) {
                    exportConfigs = await response.json();
                } else {
                    console.error("Failed to fetch export config");
                }
            } catch (error) {
                console.error("Error fetching export config:", error);
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

    async function startExport(pipelineId) {
        appendPipelineStatus(null, `Starting ${pipelineId} pipeline...`);
        $documents.forEach(async (document) => {
            const fileList = document.map((page) => page.name);
            try {
                await fetch(API_ENDPOINTS.EXPORT_DOCUMENT, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                        pipeline: pipelineId,
                        pages: fileList,
                    }),
                });
            } catch (error) {
                appendPipelineStatus(
                    null,
                    `Error starting ${pipelineId} pipeline: ${error}`,
                );
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
    {#each exportConfigs as config}
        <PipelineButton
            text={config.label}
            on:click={() => startExport(config.id)}
        />
    {/each}
{/if}
