<script>
    //export let isRunning;
    import { isRunning } from "./store.js";
</script>

<button on:click disabled={$isRunning}> Run Pipeline </button>

<style>
    button {
        padding: 10px 20px;
        font-size: 16px;
        background-color: #4caf50;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        transition: background-color 0.3s;
    }

    button:hover {
        background-color: #45a049;
    }

    button:disabled {
        background-color: #cccccc;
        cursor: not-allowed;
    }
</style>
