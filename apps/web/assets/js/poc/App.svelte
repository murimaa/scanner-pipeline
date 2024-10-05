<script>
    import SelectedPages from "./SelectedPages.svelte";
    import PipelineConsole from "./PipelineConsole.svelte";
    import PipelineRunner from "./PipelineRunner.svelte";
    import AvailablePages from "./AvailablePages.svelte";

    let dropTargetElement;
</script>

<main>
    <PipelineRunner />
    <div class="documents">
        <SelectedPages bind:dropTarget={dropTargetElement} />
        <AvailablePages dropTarget={dropTargetElement} />
    </div>
    <h2>Pipeline Runner</h2>
    <PipelineConsole />
</main>

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
    h2 {
        text-align: center;
        color: #333;
        margin-bottom: 20px;
    }
</style>
