#!/bin/bash
rm src_code_blob
touch src_code_blob
cat main.asm >> src_code_blob
echo "" >> src_code_blob
cat loader.asm >> src_code_blob
echo "" >> src_code_blob
cat screen.asm >> src_code_blob
echo "Generated src code blob."
