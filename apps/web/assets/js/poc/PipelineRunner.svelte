<script>
    import { onMount, onDestroy } from "svelte";
    import { isRunning, pipelineStatus, scriptStatuses } from "./store.js";
    import RunButton from "./RunButton.svelte";
    import StatusDisplay from "./StatusDisplay.svelte";
    import PipelineStatus from "./PipelineStatus.svelte";
    import { createEventSourceManager } from "./eventSourceManager.js";
    import { RECONNECT_DELAY, API_ENDPOINTS } from "./constants.js";

    let eventSourceManager;

    onMount(() => {
        eventSourceManager = createEventSourceManager(
            API_ENDPOINTS.STREAM_STATUS,
            handleStatusUpdate,
            handleEventSourceOpen,
            handleEventSourceError,
            RECONNECT_DELAY,
        );
        eventSourceManager.connect();

        return () => {
            eventSourceManager.disconnect();
        };
    });

    function handleEventSourceOpen() {
        appendPipelineStatus("Connected to status stream");
    }

    function handleEventSourceError(error) {
        appendPipelineStatus(
            `Error in status stream: ${error}. Attempting to reconnect...`,
        );
    }

    function handleStatusUpdate(data) {
        switch (data.event) {
            case "script_started":
                handleScriptStarted(data.script);
                break;
            case "script_finished":
                handleScriptFinished(data.script);
                break;
            case "script_failed":
                handleScriptFailed(data.script, data.reason);
                break;
            case "pipeline_failed":
                handlePipelineFailed(data.reason);
                break;
            case "pipeline_finished":
                handlePipelineFinished();
                break;
        }
    }

    function handleScriptStarted(script) {
        $scriptStatuses = [
            ...$scriptStatuses.map((s) => ({ ...s, isCurrentStatus: false })),
            {
                id: Date.now(),
                script,
                status: "running",
                isCurrentStatus: true,
            },
        ];
    }

    function handleScriptFinished(script) {
        $scriptStatuses = $scriptStatuses.map((s) =>
            s.script === script
                ? { ...s, status: "finished", isCurrentStatus: false }
                : s,
        );
    }

    function handleScriptFailed(script, reason) {
        $scriptStatuses = $scriptStatuses.map((s) =>
            s.script === script
                ? { ...s, status: "failed", reason, isCurrentStatus: false }
                : s,
        );
    }

    function handlePipelineFailed(reason) {
        appendPipelineStatus(`Pipeline failed: ${reason}`);
        $isRunning = false;
    }

    function handlePipelineFinished() {
        appendPipelineStatus("Pipeline completed successfully.");
        $isRunning = false;
    }

    function appendPipelineStatus(message) {
        $pipelineStatus = [...$pipelineStatus, { message }];
    }

    async function runPipeline() {
        $isRunning = true;
        appendPipelineStatus("Starting pipeline...");

        try {
            await fetch(API_ENDPOINTS.RUN_PIPELINE, { method: "POST" });
        } catch (error) {
            appendPipelineStatus(`Error starting pipeline: ${error}`);
            $isRunning = false;
        }
    }
</script>

<RunButton on:click={runPipeline} />
<PipelineStatus />
<StatusDisplay />
