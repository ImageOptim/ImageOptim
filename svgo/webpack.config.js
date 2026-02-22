"use strict";
const path = require("path");
const webpack = require("webpack");

module.exports = {
    cache: true,
    context: __dirname,
    entry: "./index.js",
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
