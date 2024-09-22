<script>
    import { onMount } from "svelte";
    import {
        currentStatus,
        statusMessages,
        isRunning,
        pipelineStatus,
    } from "./store.js";
    import RunButton from "./RunButton.svelte";
    import StatusDisplay from "./StatusDisplay.svelte";
    import PipelineStatus from "./PipelineStatus.svelte";

    const spinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
    let eventSource;
    let currentSpinnerIndex = 0;
    let spinnerInterval;
    const RECONNECT_DELAY = 5000; // 5 seconds

    onMount(() => {
        connectToEventStream();
        return () => {
            if (eventSource) eventSource.close();
            if (reconnectTimeout) clearTimeout(reconnectTimeout);
            if (spinnerInterval) clearInterval(spinnerInterval);
        };
    });

    function connectToEventStream() {
        if (eventSource) {
            eventSource.close();
        }

        $pipelineStatus = [
            ...$pipelineStatus,
            `Connecting to status stream...`,
        ];

        eventSource = new EventSource("/api/pipeline/stream_status");

        eventSource.onopen = () => {
            $pipelineStatus = [
                ...$pipelineStatus,
                `Connected to status stream`,
            ];
            if (reconnectTimeout) {
                clearTimeout(reconnectTimeout);
                reconnectTimeout = null;
            }
        };

        eventSource.onmessage = (event) => {
            const data = JSON.parse(event.data);
            handleStatusUpdate(data);
        };

        eventSource.onerror = (error) => {
            $pipelineStatus = [
                ...$pipelineStatus,
                `Error in status stream: ${error}. Attempting to reconnect...`,
            ];
            eventSource.close();
            reconnectTimeout = setTimeout(
                connectToEventStream,
                RECONNECT_DELAY,
            );
        };
    }

    function handleStatusUpdate(data) {
        switch (data.event) {
            case "script_started":
                if ($currentStatus && $currentStatus.status === "started") {
                    updateStatus("✓", "green");
                }
                $currentStatus = { script: data.script, status: "started" };
                appendStatus(
                    formatStatus(spinnerFrames[currentSpinnerIndex]),
                    "blue",
                    true,
                );
                startSpinner();
                break;
            case "script_finished":
                stopSpinner();
                $currentStatus.status = "finished";
                updateStatus("✓", "green");
                $currentStatus = null;
                break;
            case "script_failed":
                stopSpinner();
                $currentStatus.status = "failed";
                updateStatus("✗", "red");
                appendStatus(`Script failed: ${data.script}`, "red");
                appendStatus(`Reason: ${data.reason}`, "red");
                $currentStatus = null;
                break;
            case "pipeline_failed":
                $pipelineStatus = [
                    ...$pipelineStatus,
                    `Pipeline failed: ${data.reason}`,
                ];
                stopSpinner();
                $isRunning = false;
                break;
            case "pipeline_finished":
                $pipelineStatus = [
                    ...$pipelineStatus,
                    "Pipeline completed successfully.",
                ];
                stopSpinner();
                $isRunning = false;
                break;
        }
    }

    function startSpinner() {
        if (!spinnerInterval) {
            spinnerInterval = setInterval(() => {
                currentSpinnerIndex =
                    (currentSpinnerIndex + 1) % spinnerFrames.length;
                updateStatus(spinnerFrames[currentSpinnerIndex], "blue");
            }, 100);
        }
    }

    function stopSpinner() {
        if (spinnerInterval) {
            clearInterval(spinnerInterval);
            spinnerInterval = null;
        }
    }

    function formatStatus(prefix) {
        if ($currentStatus) {
            return `${prefix} ${$currentStatus.script}: ${$currentStatus.status}`;
        }
        return "";
    }

    function updateStatus(prefix, color) {
        $statusMessages = $statusMessages.map((msg, index) =>
            index === $statusMessages.length - 1 && msg.isCurrentStatus
                ? { ...msg, message: formatStatus(prefix), color }
                : msg,
        );
    }

    function appendStatus(message, color = "black", isCurrentStatus = false) {
        $statusMessages = [
            ...$statusMessages,
            { message, color, isCurrentStatus },
        ];
    }

    async function runPipeline() {
        $isRunning = true;
        $pipelineStatus = [...$pipelineStatus, "Starting pipeline..."];

        try {
            await fetch("/api/pipeline/run", { method: "POST" });
        } catch (error) {
            $pipelineStatus = [
                ...$pipelineStatus,
                `Error starting pipeline: ${error}`,
            ];
            $isRunning = false;
        }
    }
</script>

<RunButton on:click={runPipeline} />
<PipelineStatus />
<StatusDisplay />
