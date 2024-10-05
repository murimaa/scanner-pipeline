<script>
    import { onMount, afterUpdate } from "svelte";
    import SelectedPages from "./documents/SelectedPages.svelte";
    import AvailablePages from "./documents/AvailablePages.svelte";
    import PipelineConsole from "./console/PipelineConsole.svelte";
    import PipelineRunner from "./toolbar/PipelineRunner.svelte";

    let dropTargetElement;
    let consoleWrapper;
    let main;

    function adjustMainPadding() {
        if (consoleWrapper && main) {
            const consoleHeight = consoleWrapper.offsetHeight;
            main.style.paddingBottom = `${consoleHeight + 20}px`; // 20px extra for spacing
        }
    }

    function scrollConsoleToBottom() {
        if (consoleWrapper) {
            consoleWrapper.scrollTop = consoleWrapper.scrollHeight;
        }
    }

    onMount(() => {
        adjustMainPadding();
        // Set up a MutationObserver to watch for changes in the console content
        const observer = new MutationObserver(() => {
            adjustMainPadding();
            scrollConsoleToBottom();
        });
        observer.observe(consoleWrapper, { childList: true, subtree: true });
    });

    afterUpdate(() => {
        adjustMainPadding();
        scrollConsoleToBottom();
    });
</script>

<main bind:this={main}>
    <div class="buttons-wrapper">
        <PipelineRunner />
    </div>
    <div class="documents">
        <div class="container selected">
            <h2>Documents</h2>
            <SelectedPages bind:dropTarget={dropTargetElement} />
        </div>
        <div class="container available">
            <h2>Available pages</h2>
            <AvailablePages dropTarget={dropTargetElement} />
        </div>
    </div>
</main>
<div class="console-wrapper" bind:this={consoleWrapper}>
    <PipelineConsole />
</div>

<style>
    main {
        width: 90vw;
        max-width: 1000px;
        margin: 0 auto;
        padding: 20px;
    }
    .documents {
        display: flex;
        gap: 20px;
        max-width: 100%;
        overflow-x: hidden;
    }
    .container {
        border-radius: 15px;
        padding: 15px;
    }
    .container h2 {
        text-align: center;
        font-size: 1.25rem;
    }
    .container.available {
        flex: 2;
        border: 5px #f0f0f0 solid;
    }
    .container.selected {
        flex: 1;
        background-color: #f0f0f0;
    }
    .buttons-wrapper {
        margin: 1rem 0;
    }
    .console-wrapper {
        position: fixed;
        bottom: 0;
        left: 0;
        right: 0;
        max-height: 10rem;
        overflow-y: auto;
        background-color: white;
        box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
        z-index: 1000;
    }
</style>
