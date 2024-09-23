<script>
    import { onMount, onDestroy } from "svelte";

    export let executionId;
    export let text;
    export let status;
    export let isCurrentStatus;

    const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
    let spinnerIndex = 0;
    let spinnerInterval;

    $: statusSymbol = getStatusSymbol(status, spinnerIndex);
    $: statusColor = getStatusColor(status);

    function getStatusSymbol(status, spinnerIndex) {
        switch (status) {
            case "finished":
                return "✓";
            case "failed":
                return "✗";
            case "running":
                return SPINNER_FRAMES[spinnerIndex];
            default:
                return "";
        }
    }

    function getStatusColor(status) {
        switch (status) {
            case "finished":
                return "green";
            case "failed":
                return "red";
            case "running":
                return "blue";
            default:
                return "black";
        }
    }

    onMount(() => {
        if (status === "running") {
            startSpinner();
        }
    });

    onDestroy(() => {
        stopSpinner();
    });

    $: if (status === "running") {
        startSpinner();
    } else {
        stopSpinner();
    }

    function startSpinner() {
        if (!spinnerInterval) {
            spinnerInterval = setInterval(async () => {
                spinnerIndex = (spinnerIndex + 1) % SPINNER_FRAMES.length;
            }, 100);
        }
    }

    function stopSpinner() {
        if (spinnerInterval) {
            clearInterval(spinnerInterval);
            spinnerInterval = null;
        }
    }
</script>

<div class:current-status={isCurrentStatus}>
    <span style="color: {statusColor}">{statusSymbol} {executionId} {text}</span
    >
</div>

<style>
    div {
        margin: 0;
        padding: 0;
    }
    .current-status {
        font-weight: bold;
    }
</style>
