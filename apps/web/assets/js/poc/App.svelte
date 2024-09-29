<script>
    import PipelineConsole from "./PipelineConsole.svelte";
    import PipelineRunner from "./PipelineRunner.svelte";
</script>

<main>
    <h1>Pipeline Runner</h1>
    <PipelineRunner />
    <PipelineConsole />
</main>

<style>
    main {
        max-width: 800px;
        margin: 0 auto;
        padding: 20px;
    }

    h1 {
        text-align: center;
        color: #333;
        margin-bottom: 20px;
    }
</style>
