const str = '\\\\text';
const out1 = str.replace(/\\\\(text)/g, '\\$1');
const out2 = str.replace(/\\\\(text)/g, '\\\\$1');
console.log('out1:', JSON.stringify(out1));
console.log('out2:', JSON.stringify(out2));
