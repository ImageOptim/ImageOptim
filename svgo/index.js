"use strict";

const SVGO = require('svgo');
const fs = require('fs');

const svgo = new SVGO({
    full: true,
    plugins: [
        'removeDoctype',
        'removeXMLProcInst',
        'removeComments',
        'removeMetadata',
        'removeXMLNS',
        'removeEditorsNSData',
        'cleanupAttrs',
        'minifyStyles',
        'convertStyleToAttrs',
        'cleanupIDs',
        'removeRasterImages',
        'removeUselessDefs',
        'cleanupNumericValues',
        'cleanupListOfValues',
        'convertColors',
        'removeUnknownsAndDefaults',
        'removeNonInheritableGroupAttrs',
        'removeUselessStrokeAndFill',
        'removeViewBox',
        'cleanupEnableBackground',
        'removeHiddenElems',
        'removeEmptyText',
        'convertShapeToPath',
        'moveElemsAttrsToGroup',
        'moveGroupAttrsToElems',
        'collapseGroups',
        'convertPathData',
        'convertTransform',
        'removeEmptyAttrs',
        'removeEmptyContainers',
        'mergePaths',
        'removeUnusedNS',
        'transformsWithOnePath',
        'sortAttrs',
        'removeTitle',
        'removeDesc',
        'removeDimensions',
        'removeAttrs',
        'removeElementsByAttr',
        'addClassesToSVGElement',
        'removeStyleElement',
        'addAttributesToSVGElement',
    ],
});

try {
    const inFile = process.argv[2];
    const outFile = process.argv[3];
    const svgstr = fs.readFileSync(inFile);

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
