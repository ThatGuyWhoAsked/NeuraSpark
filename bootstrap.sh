#!/usr/bin/env bash

set -e

echo "Creating AI Learning BYOK project..."
APP_NAME="ai-learning-byok"
mkdir $APP_NAME
cd $APP_NAME

echo "Initializing Next.js..."
npx create-next-app@latest . --ts --eslint --src-dir --no-tailwind --app --import-alias "@/*"

echo "Installing dependencies..."
npm install axios uuid

echo "Creating directories..."
mkdir -p src/lib src/components

########################################
# WRITE FILES
########################################

# lib/cerebras.ts
cat << 'EOF' > src/lib/cerebras.ts
import axios from "axios";

export async function generateCompletion(request, userKey) {
  if (!userKey) throw new Error("Missing Cererbras key");

  const res = await axios.post(
    "/api/proxy",
    request,
    { headers: { Authorization: `Bearer ${userKey}` } }
  );

  return res.data;
}
EOF

# lib/byokStorage.ts
cat << 'EOF' > src/lib/byokStorage.ts
export const STORAGE_KEY = "cerebras_byok_plain_v1";

export function saveKeyPlain(key: string) {
  localStorage.setItem(STORAGE_KEY, key);
}

export function loadKeyPlain(): string | null {
  return localStorage.getItem(STORAGE_KEY);
}

export function clearKey() {
  localStorage.removeItem(STORAGE_KEY);
}
EOF


# components/Chat.tsx
cat << 'EOF' > src/components/Chat.tsx
"use client";
import React, { useState } from "react";
import { generateCompletion } from "../lib/cerebras";
import { loadKeyPlain } from "../lib/byokStorage";

export default function Chat() {
  const [skill, setSkill] = useState("beginner");
  const [input, setInput] = useState("");
  const [messages, setMessages] = useState([]);
  const apiKey = loadKeyPlain();

  async function send() {
    const prompt = {
      model: "cerebras-llm-1",
      input:
        \`You are EduAssist. Skill level: \${skill}. Respond in JSON.
User: \${input}\`,
      max_tokens: 600,
    };

    const res = await generateCompletion(prompt, apiKey);
    setMessages((m) => [...m, { role: "user", text: input }, { role: "assistant", text: JSON.stringify(res, null, 2) }]);
    setInput("");
  }

  return (
    <div style={{ padding: 20 }}>
      <h2>Chat Assistant</h2>
      <label>Skill Level:</label>
      <select value={skill} onChange={(e) => setSkill(e.target.value)}>
        <option value="beginner">Beginner</option>
        <option value="intermediate">Intermediate</option>
        <option value="advanced">Advanced</option>
      </select>

      <div style={{ border: "1px solid #ccc", marginTop: 20, padding: 10, height: 300, overflow: "auto" }}>
        {messages.map((m, i) => (
          <div key={i}>
            <strong>{m.role}:</strong>
            <pre>{m.text}</pre>
          </div>
        ))}
      </div>

      <textarea
        rows={3}
        value={input}
        onChange={(e) => setInput(e.target.value)}
        style={{ width: "100%", marginTop: 20 }}
      />

      <button onClick={send} disabled={!apiKey}>Send</button>
    </div>
  );
}
EOF

# components/OnboardingBYOK.tsx
cat << 'EOF' > src/components/OnboardingBYOK.tsx
"use client";
import React, { useState } from "react";
import { saveKeyPlain, clearKey } from "../lib/byokStorage";

export default function OnboardingBYOK({ onDone }) {
  const [key, setKey] = useState("");

  return (
    <div style={{ padding: 20 }}>
      <h2>Bring Your Own Key — Cerebras</h2>
      <p>This app never stores your API key on a server. It stays in your browser only.</p>

      <input
        placeholder="sk-..."
        value={key}
        onChange={(e) => setKey(e.target.value)}
        style={{ width: "100%" }}
      />

      <button
        onClick={() => {
          saveKeyPlain(key);
          onDone();
        }}
      >
        Save Key
      </button>

      <button onClick={clearKey} style={{ marginLeft: 10 }}>
        Clear Key
      </button>
    </div>
  );
}
EOF

# app/page.tsx
cat << 'EOF' > src/app/page.tsx
"use client";
import { useState } from "react";
import OnboardingBYOK from "../components/OnboardingBYOK";
import Chat from "../components/Chat";
import { loadKeyPlain } from "../lib/byokStorage";

export default function App() {
  const [hasKey, setHasKey] = useState(!!loadKeyPlain());

  return hasKey ? <Chat /> : <OnboardingBYOK onDone={() => setHasKey(true)} />;
}
EOF

# pages/api/proxy (Next.js serverless API)
mkdir -p src/pages/api
cat << 'EOF' > src/pages/api/proxy.ts
import type { NextApiRequest, NextApiResponse } from "next";
import fetch from "node-fetch";

const BASE = "https://api.cerebras.ai/v1";

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ error: "Missing user key" });

  try {
    const upstream = await fetch(\`\${BASE}/completions\`, {
      method: "POST",
      headers: {
        Authorization: auth,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(req.body),
    });

    const text = await upstream.text();
    res.status(upstream.status).send(text);
  } catch (e) {
    res.status(500).json({ error: "Cerebras upstream request failed" });
  }
}
EOF

########################################
# Git init
########################################

echo "Initializing Git..."
git init
git add .
git commit -m "Initial BYOK AI Learning App"

echo "Done!"
echo ""
echo "Next Steps:"
echo "1. Create a new GitHub repo."
echo "2. Run:"
echo "     git remote add origin <YOUR-REPO-URL>"
echo "     git branch -M main"
echo "     git push -u origin main"
echo "3. Deploy to Vercel: https://vercel.com/new"
echo ""
echo "You're ready to go! 🚀"

