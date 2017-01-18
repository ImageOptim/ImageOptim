"use strict";

const SVGO = require('svgo');
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
    'addAttributesToSVGElement',
    'addClassesToSVGElement',
    'cleanupEnableBackground',
    'cleanupIDs',
    'collapseGroups',
    'convertPathData',
    'convertShapeToPath',
    'convertTransform',
    'mergePaths',
    'moveElemsAttrsToGroup',
    'removeAttrs',
    'removeDesc',
    'removeDimensions',
    'removeElementsByAttr',
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
    'transformsWithOnePath',
];


try {
    const useLossy = process.argv[2];
    const inFile = process.argv[3];
    const outFile = process.argv[4];
    const svgstr = fs.readFileSync(inFile);

    const plugins = useLossy == "1" ? defaults.concat(lossy) : defaults;

    const svgo = new SVGO({
        full: true,
        plugins: plugins,
    });

    svgo.optimize(svgstr, function(result) {
        if (result.error || !result.data) {
            console.error(result.error);
            process.exit(1);
        }
        try {
            fs.writeFileSync(outFile, result.data);
        } catch(err) {
            console.error(err);
            process.exit(1);
        }
    });
} catch(err) {
    console.error(err);
    process.exit(1);
}
