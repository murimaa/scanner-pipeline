<script>
    import { onMount, onDestroy } from "svelte";
    import { thumbnails } from "./store.js";
    import { createEventSourceManager } from "./eventSourceManager.js";
    import { RECONNECT_DELAY, API_ENDPOINTS } from "./constants.js";

    let eventSourceManager;

    onMount(() => {
        eventSourceManager = createEventSourceManager(
            API_ENDPOINTS.THUMBNAIL_STREAM,
            handleThumbnailUpdate,
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
        console.log("Connected to thumbnail stream");
    }

    function handleEventSourceError(error) {
        console.error(
            `Error in thumbnail stream: ${error}. Attempting to reconnect...`,
        );
    }

    function handleThumbnailUpdate(data) {
        if (data.event === "thumbnails") {
            $thumbnails = data.data;
        }
    }
    function stripExtension(filename) {
        return filename.substring(0, filename.lastIndexOf(".")) || filename;
    }
    async function deleteThumbnail(filename) {
        try {
            const response = await fetch(
                `${API_ENDPOINTS.DELETE_PAGE}/${stripExtension(filename)}`,
                {
                    method: "DELETE",
                },
            );
            if (response.ok) {
                $thumbnails = $thumbnails.filter((t) => t.name !== filename);
            } else {
                console.error("Failed to delete thumbnail");
            }
        } catch (error) {
            console.error("Error deleting thumbnail:", error);
        }
    }
</script>

<div class="thumbnail-container">
    {#each $thumbnails as thumbnail (thumbnail.name)}
        <div class="thumbnail">
            <img src={thumbnail.url} alt={thumbnail.name} />
            <button
                class="delete-btn"
                on:click={() => deleteThumbnail(thumbnail.name)}
            >
                🗑️
            </button>
            <p>{thumbnail.name}</p>
        </div>
    {/each}
</div>

<style>
    .thumbnail-container {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
    }

    .thumbnail {
        width: 80vw;
        text-align: center;
        position: relative;
    }

    .thumbnail img {
        max-width: 100%;
        height: auto;
    }

    .thumbnail p {
        margin-top: 5px;
        font-size: 0.8em;
        word-break: break-all;
    }

    .delete-btn {
        position: absolute;
        top: 5px;
        right: 5px;
        background-color: rgba(255, 255, 255, 0.7);
        border: none;
        border-radius: 50%;
        width: 30px;
        height: 30px;
        font-size: 16px;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0;
    }

    .delete-btn:hover {
        background-color: rgba(255, 0, 0, 0.7);
        color: white;
    }
</style>
