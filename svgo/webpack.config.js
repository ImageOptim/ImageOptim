"use strict";
const path = require("path");
const webpack = require("webpack");

module.exports = {
    cache: true,
    context: __dirname,
    entry: "./index.js",
    externals: {
        'js-yaml': "undefined", // Pulls in Esprima. YAML is not needed anyway.
        './utils/translateWithSourceMap': '{}', // Removes sourceMap support from CSSO.
    },
    output: {
        path: path.join(__dirname, "build"),
        filename: "svgo.js",
    },
    module: {
        loaders: [{
            test: /\.json$/,
            loader: 'json-loader',
        }],
    },
    target: "node",
    plugins: [
        new webpack.optimize.UglifyJsPlugin({
            compress: {
                warnings: false,
            },
        }),
    ],
};
