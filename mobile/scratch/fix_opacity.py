import os
import re

def fix_with_opacity(root_dir):
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = re.sub(r'withOpacity\((0\.\d+)\)', r'withValues(alpha: \1)', content)
                
                if new_content != content:
                    print(f"Fixing {path}")
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)

if __name__ == "__main__":
    fix_with_opacity('c:\\Users\\musny\\Desktop\\Hashnate\\PBN\\mobile\\lib')
