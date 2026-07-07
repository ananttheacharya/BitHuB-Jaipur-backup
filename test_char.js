const str = '\\\\text'.replace(/\\\\(text)/g, '\\$1');
console.log('Result length:', str.length);
for (let i = 0; i < str.length; i++) {
  console.log(i, str[i], str.charCodeAt(i));
}
