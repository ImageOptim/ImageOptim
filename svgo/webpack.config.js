"use strict";
const path = require("path");
const webpack = require("webpack");

module.exports = {
    cache: true,
    context: __dirname,
    entry: "./index.js",
    externals: {
        'js-yaml': "undefined", // Pulls in Esprima. YAML is not needed anyway.
        './utils/traslateWithSourceMap': '{}', // 0.7 Removes sourceMap support from CSSO.
        './sourceMap': '{}', // 1.0 Removes sourceMap support from CSSO.
    },
    output: {
        path: path.join(__dirname, "build"),
        filename: "svgo.js",
    },
    target: "node",
    mode: "production",
    optimization: {
        minimize: true,
    },
};
