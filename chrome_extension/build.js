// Build script for RESET AI Chrome Extension
import esbuild from 'esbuild';

// Build popup bundle
esbuild.buildSync({
    entryPoints: ['src/popup.js'],
    bundle: true,
    outfile: 'dist/popup.bundle.js',
    format: 'iife',
    minify: false,
    sourcemap: false
});

// Build dashboard bundle
esbuild.buildSync({
    entryPoints: ['src/dashboard.js'],
    bundle: true,
    outfile: 'dist/dashboard.bundle.js',
    format: 'iife',
    minify: false,
    sourcemap: false
});

// Build background bundle
esbuild.buildSync({
    entryPoints: ['src/background.js'],
    bundle: true,
    outfile: 'dist/background.bundle.js',
    format: 'iife',
    platform: 'browser',
    target: 'es2020',
    define: {
        'global': 'self'
    },
    banner: {
        js: 'if (typeof window === "undefined") { self.window = self; }'
    },
    minify: false,
    sourcemap: false
});

console.log('Build complete!');
