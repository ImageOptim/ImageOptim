"use strict";

const { optimize } = require('svgo');
const fs = require('fs');

const defaults = [
    'cleanupAttrs',
    'cleanupListOfValues',
    'cleanupNumericValues',
    'convertColors',
    'convertStyleToAttrs',
    'minifyStyles',
    'moveGroupAttrsToElems',
    'removeComments',
    'removeDoctype',
    'removeEditorsNSData',
    'removeEmptyAttrs',
    'removeEmptyContainers',
    'removeEmptyText',
    'removeNonInheritableGroupAttrs',
    'removeXMLProcInst',
    'sortAttrs',
];

const lossy = [
    'cleanupEnableBackground',
    'cleanupIds',
    'collapseGroups',
    'convertPathData',
    'convertShapeToPath',
    'convertTransform',
    'mergePaths',
    'moveElemsAttrsToGroup',
    'removeDesc',
    'removeDimensions',
    'removeHiddenElems',
    'removeMetadata',
    'removeRasterImages',
    'removeStyleElement',
    'removeTitle',
    'removeUnknownsAndDefaults',
    'removeUnusedNS',
    'removeUselessDefs',
    'removeUselessStrokeAndFill',
    'removeViewBox',
    'removeXMLNS',
];


try {
    const useLossy = process.argv[2];
    const inFile = process.argv[3];
    const outFile = process.argv[4];
    const svgstr = fs.readFileSync(inFile, 'utf8');

    const plugins = useLossy == "1" ? defaults.concat(lossy) : defaults;

    const result = optimize(svgstr, {
        plugins: plugins,
    });

    if (!result.data) {
        console.error('SVGO returned no data');
        process.exit(1);
    }

    fs.writeFileSync(outFile, result.data);
} catch(err) {
    console.error(err);
    process.exit(1);
}
