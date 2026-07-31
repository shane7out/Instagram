# The Prompt Room

A website that shows the story behind every AI-made song: the ChatGPT prompt
that started it, the Suno style it produced, and the lyrics — displayed right
next to the finished song. Visitors can also request a custom song of their own.

The whole site is two files:

| File | What it is |
|---|---|
| `index.html` | The website itself. You should not need to touch this. |
| `songs.js` | **Your content.** Every song, prompt, style, and lyric lives here. This is the only file you edit. |

## Adding a song

Open `songs.js` and add one entry to the `SONGS` list for each track:

```js
{
  title: "My Song Name",
  genreTags: ["Country soul", "Wedding"],
  chatgptPrompt: "The exact prompt you typed into ChatGPT…",
  style: "The style text ChatGPT gave you (what you pasted into Suno's Style box)",
  lyrics: "[Verse 1]\nThe lyrics…\n\n[Chorus]\n…",
  sunoUrl: "https://suno.com/song/your-song-id",
  audioUrl: "",   // optional: direct link to an .mp3 if you host the file
},
```

Notes:

- **sunoUrl** — on Suno, open the song and copy its Share link. The site
  automatically turns it into an embedded player.
- **audioUrl** — only needed if you'd rather host the .mp3 yourself; leave it
  as `""` otherwise.
- In lyrics, `\n` means "new line". Blank line between sections = `\n\n`.
- Two **sample songs** are included so you can see the layout — delete them
  once your real songs are in.

At the top of `songs.js` there's also a `CONFIG` block where you set the site
name, tagline, and the email address that custom-song requests go to.

## The request form (monetization)

Out of the box, the "Request my song" button opens the visitor's email app
with their request pre-filled and addressed to your `contactEmail`.

When you're ready for something more polished:

1. Create a free form at [formspree.io](https://formspree.io) (requests get
   emailed to you and collected in a dashboard).
2. Paste your endpoint into `formspreeEndpoint` in `songs.js`.

To charge for songs later, the simplest path is a
[Stripe Payment Link](https://stripe.com/payments/payment-links) — create one,
then add it as a "Pay & request" button or include it in your reply emails.
No code changes needed to start taking requests today, though.

## Putting it online (free)

Easiest option — **GitHub Pages**:

1. In this repository on GitHub, go to **Settings → Pages**.
2. Under "Build and deployment", choose **Deploy from a branch**, pick your
   branch, and set the folder to `/prompt-room` (or move these files into
   their own repository and use `/root`).
3. Your site appears at `https://<your-username>.github.io/<repo-name>/`.

Also easy: drag the `prompt-room` folder onto [netlify.com/drop](https://app.netlify.com/drop)
— you get a live URL in seconds, and can attach a custom domain
(like `thepromptroom.com`) later.

## Previewing on your computer

Just double-click `index.html` — it opens in your browser and works fully,
including the Suno players (internet connection required for those).
