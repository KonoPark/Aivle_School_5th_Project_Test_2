import { NextResponse } from "next/server";

export async function POST(req) {
    try {
        const { apiKey, model, prompt } = await req.json();

        if (!apiKey) {
            return NextResponse.json(
                { error: "API key is missing" },
                { status: 400 }
            );
        }

        const openaiRes = await fetch("https://api.openai.com/v1/images/generations", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${apiKey}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                model: model || "dall-e-3",
                prompt,
                n: 1,
                size: "1024x1024"
            })
        });

        const json = await openaiRes.json();

        if (!openaiRes.ok) {
            console.error("OpenAI API Error:", json);
            return NextResponse.json({ error: json.error?.message || "OpenAI Error" }, { status: 500 });
        }

        return NextResponse.json(json, { status: 200 });

    } catch (err) {
        console.error("Route error:", err);
        return NextResponse.json({ error: err.message }, { status: 500 });
    }
}
