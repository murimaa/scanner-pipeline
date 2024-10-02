<script>
    import { onMount, onDestroy } from "svelte";
    import { documents, thumbnails } from "./store.js";
    import { createEventSourceManager } from "./eventSourceManager.js";
    import {
        TRANSITION_DURATION,
        RECONNECT_DELAY,
        API_ENDPOINTS,
    } from "./constants.js";
    import { fly, fade } from "svelte/transition";

    let eventSourceManager;
    let selectedPages = [];
    let selectedContainer;

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
                // Remove from selectedPages if it was selected
                selectedPages = selectedPages.filter(
                    (p) => p.name !== filename,
                );
            } else {
                console.error("Failed to delete thumbnail");
            }
        } catch (error) {
            console.error("Error deleting thumbnail:", error);
        }
    }

    function selectPage(thumbnail) {
        // Select all pages up until the one clicked
        const index = $thumbnails.findIndex((t) => t.name === thumbnail.name);
        if (index !== -1) {
            const pagesToAdd = $thumbnails
                .slice(0, index + 1)
                .filter((t) => !selectedPages.some((s) => s.name === t.name));
            selectedPages = [...selectedPages, ...pagesToAdd];
            setTimeout(() => {
                $documents = [...$documents, pagesToAdd];
            }, TRANSITION_DURATION);
        }
    }

    function unselectDocument(document) {
        newDocuments = documents.filter((d) => d !== document);
        selectedPages = $thumbnails.filter((t) =>
            newDocuments
                .flat()
                .map((p) => p.name)
                .includes(t.name),
        );
        $documents = newDocuments;
    }

    $: remainingThumbnails = $thumbnails.filter(
        (t) => !selectedPages.some((s) => s.name === t.name),
    );

    function flyAndScale(node, { delay = 0, duration = 400, target } = {}) {
        const style = getComputedStyle(node);
        const getCoords = (elem) => ({
            x: elem.getBoundingClientRect().left,
            y: elem.getBoundingClientRect().top,
        });
        const dx = getCoords(target).x - getCoords(node).x;
        const dy = getCoords(target).y - getCoords(node).y;
        const scale = target.offsetWidth / node.offsetWidth;
        const transform = style.transform === "none" ? "" : style.transform;
        return {
            delay,
            duration,
            css: (t, u) => {
                const current_scale_percentage = 1 - u * (1 - scale);
                const scale_compensated_x =
                    -0.5 * node.offsetWidth * (1 - current_scale_percentage);
                const scale_compensated_y =
                    -0.5 * node.offsetHeight * (1 - current_scale_percentage);
                const translateX = scale_compensated_x + (1 - t) * dx;
                const translateY = scale_compensated_y + (1 - t) * dy;
                const css = `
			    transform: ${transform} translate(${translateX}px, ${translateY}px) scale(${current_scale_percentage});
                `;
                return css;
            },
        };
    }
</script>

<div class="main-container">
    <div class="selected-container">
        <h2>Selected Pages</h2>

        {#each $documents as document}
            {#if document.length > 0}
                <div class="selected-page">
                    <img src={document[0].url} alt={document[0].name} />
                    <button
                        class="unselect-btn"
                        on:click={() => unselectDocument(document)}
                    >
                        Unselect
                    </button>
                    <p>{document[0].name}</p>
                </div>
            {/if}
        {/each}
        <div class="drop-target" bind:this={selectedContainer}></div>
    </div>

    <div class="thumbnail-container">
        <h2>Available Pages</h2>
        {#each remainingThumbnails as thumbnail (thumbnail.name)}
            <div
                class="thumbnail"
                out:flyAndScale={{
                    target: selectedContainer,
                    duration: TRANSITION_DURATION,
                    delay: 0,
                }}
            >
                <img src={thumbnail.url} alt={thumbnail.name} />
                <button
                    class="delete-btn"
                    on:click={() => deleteThumbnail(thumbnail.name)}
                >
                    🗑️
                </button>
                <button
                    class="select-btn"
                    on:click={() => selectPage(thumbnail)}
                >
                    Select
                </button>
                <p>{thumbnail.name}</p>
            </div>
        {/each}
    </div>
</div>

<style>
    .main-container {
        display: flex;
        gap: 20px;
        max-width: 100%;
        overflow-x: hidden;
    }

    .selected-container,
    .thumbnail-container {
        display: flex;
        flex-direction: column;
        gap: 10px;
        padding: 10px;
        border-radius: 5px;
    }
    .selected-container {
        flex: 1;
    }
    .thumbnail-container {
        flex: 2;
        border: 1px solid #ccc;
    }

    .selected-page,
    .thumbnail {
        position: relative;
        width: 100%;
        text-align: center;
    }

    .selected-page img,
    .thumbnail img,
    .drop-target {
        width: 100%;
        height: auto;
    }

    .selected-page p,
    .thumbnail p {
        margin-top: 5px;
        font-size: 0.8em;
        word-break: break-all;
    }

    .unselect-btn,
    .delete-btn,
    .select-btn {
        position: absolute;
        top: 5px;
        background-color: rgba(255, 255, 255, 0.7);
        border: none;
        border-radius: 5px;
        padding: 5px 10px;
        font-size: 14px;
        cursor: pointer;
    }

    .unselect-btn {
        left: 5px;
        background-color: rgba(255, 0, 0, 0.7);
        color: white;
    }

    .delete-btn {
        right: 5px;
    }

    .select-btn {
        left: 5px;
        background-color: rgba(0, 255, 0, 0.7);
    }

    .unselect-btn:hover {
        background-color: rgba(200, 0, 0, 0.7);
    }

    .delete-btn:hover {
        background-color: rgba(255, 0, 0, 0.7);
        color: white;
    }

    .select-btn:hover {
        background-color: rgba(0, 200, 0, 0.7);
    }

    h2 {
        text-align: center;
        margin-bottom: 10px;
    }
</style>
