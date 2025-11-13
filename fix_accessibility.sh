#!/bin/bash
# Script pour corriger toutes les occurrences de accessibilityLabel avec hint

find "Tshiakani VTC" -name "*.swift" -type f | while read file; do
    # Corriger le pattern: .accessibilityLabel("text", hint: "hint")
    sed -i '' 's/\.accessibilityLabel(\([^,]*\), hint: \(.*\))/.accessibilityLabel(\1)\n            .accessibilityHint(\2)/g' "$file"
    
    # Corriger le pattern: .accessibilityLabel(variable, hint: "hint")
    sed -i '' 's/\.accessibilityLabel(\([^,]*\), hint: \(.*\))/.accessibilityLabel(\1)\n            .accessibilityHint(\2)/g' "$file"
done

echo "✅ Correction terminée"
