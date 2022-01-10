<template>
    <div>
        <h2>outage for {{currentTime}}</h2>
        <span v-if="loading">Loading...</span>
        <l-map ref="myMap" style="height: 500px" :zoom="zoom" :center="center">
            <l-tile-layer :url="url" :attribution="attribution"></l-tile-layer>
            <l-geo-json :geojson="geojson_outline" name="service area" :options-style="outlineStyle"/>
            <l-geo-json :geojson="geojson_outage" name="outages" :options="options"/>
        </l-map>
    </div>
</template>

<script>
import {LMap, LTileLayer, LGeoJson } from 'vue2-leaflet';

export default {
    components: {
        LMap,
        LTileLayer,
        LGeoJson,
    },
    data () {
        return {
            url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            attribution:
            '&copy; <a target="_blank" href="http://osm.org/copyright">OpenStreetMap</a> contributors',
            zoom: 12,
            center: [42.453606, -83.113742],
            overlayBounds: [[41.4402817, -87.1074728],[44.4353735, -79.6697286]],
            geojson_outline: null,
            geojson_outage: null,
            currentTime: "2021-11-08T18:40:01-05:00",
            outlineStyle: {fillOpacity: 0},
            loading: true,
        };
    },
    async created() {
        this.loading = true;
        const outageResponse = fetch(`${process.env.BASE_URL}/api/static/outage-${this.currentTime}.geojson`)
        const outlineResponse = fetch(`${process.env.BASE_URL}/api/static/outline.geojson`)
        this.geojson_outline = await outlineResponse.then(r => r.json());
        this.geojson_outage = await outageResponse.then(r => r.json());
        this.loading = false;
    },
    computed: {
        options() {
            return {
                onEachFeature: this.onEachFeatureFunction
            };
        },
        onEachFeatureFunction() {
            return (feature, layer) => {
                layer.bindTooltip(
                    Object.entries(feature.properties).reduce((out, [key, val]) => {
                        return out + `<div>${key}: ${val}</div>`;
                    }, ""),
                    { permanent: false, sticky: true }
                );
            };
        },
    },
}
</script>
<style>
.leaflet-image-layer {
         image-rendering: crisp-edges
}
</style>
