/* ============================================================
   THE PROMPT ROOM — YOUR CONTENT LIVES HERE
   This is the ONLY file you need to edit to add songs.

   For each song you made with Suno, add one entry to the SONGS
   list below with:
     title     — the song's name
     genreTags — short labels shown on the card (genre, mood)
     chatgptPrompt — the exact prompt you typed into ChatGPT
     style     — the style text ChatGPT gave you (what you paste
                 into Suno's "Style of Music" box)
     lyrics    — the lyrics ChatGPT wrote (what you paste into
                 Suno's "Lyrics" box)
     sunoUrl   — the share link to the song on Suno, e.g.
                 https://suno.com/song/xxxxxxxx-xxxx-....
                 (the site turns this into an embedded player)
     audioUrl  — OPTIONAL: a direct link to an .mp3 file if you
                 downloaded the song and host the file yourself.
                 If set, a built-in audio player is shown too.

   Delete the sample songs once you've added your real ones.
   ============================================================ */

const CONFIG = {
  siteName: "The Prompt Room",
  tagline: "Every song starts as a sentence.",

  // Where custom-song requests go. The request form opens the
  // visitor's email app with everything pre-filled, addressed here.
  contactEmail: "claude.lasvegasrestaurants@gmail.com",

  // OPTIONAL — later, if you want requests delivered without email:
  // create a free form at https://formspree.io, then paste your
  // endpoint here (looks like "https://formspree.io/f/abcdwxyz").
  // The form will submit directly instead of opening email.
  formspreeEndpoint: "",

  // Shown on the request panel. Change or clear when you set pricing.
  requestNote: "Custom songs are open for requests — pricing on reply.",
};

const SONGS = [
  {
    title: "Neon Mirage (sample — replace me)",
    genreTags: ["Synthwave", "Late-night drive"],
    chatgptPrompt:
      "Write me a song for Suno about driving down the Las Vegas Strip " +
      "at 2am when all the tourists are gone. I want it to feel lonely " +
      "but beautiful. Give me a style description Suno can use and full " +
      "lyrics with verses, a chorus, and a bridge.",
    style:
      "Dreamy synthwave, 92 BPM, warm analog pads, gated reverb drums, " +
      "male vocal with light vocoder harmonies, nostalgic and cinematic, " +
      "night-drive mood",
    lyrics:
      "[Verse 1]\n" +
      "Two a.m. and the fountains sleep\n" +
      "Neon ghosts in the window keep\n" +
      "Promises the daylight never made\n\n" +
      "[Chorus]\n" +
      "Neon mirage, you shine for no one\n" +
      "Burning bright when the crowd is gone\n" +
      "I'm the only witness on the boulevard\n" +
      "Neon mirage, keep my headlights company\n\n" +
      "[Verse 2]\n" +
      "Valet stands like an empty throne\n" +
      "Every jackpot bell has flown\n" +
      "Down the Strip where the silence pays\n\n" +
      "[Bridge]\n" +
      "When the sun comes up I'll disappear\n" +
      "But tonight the whole town's mine right here",
    sunoUrl: "",
    audioUrl: "",
  },
  {
    title: "Front Porch Gospel (sample — replace me)",
    genreTags: ["Country soul", "Sunday morning"],
    chatgptPrompt:
      "I need a Suno song that sounds like Sunday morning at my " +
      "grandmother's house in the South — biscuits, gospel radio, " +
      "screen door slamming. Warm and joyful, not sad. Give me the " +
      "Suno style line and complete lyrics.",
    style:
      "Country soul with gospel choir backing, 78 BPM, dobro and warm " +
      "upright piano, handclaps, rich female lead vocal, joyful and " +
      "front-porch intimate",
    lyrics:
      "[Verse 1]\n" +
      "Flour on her hands and the radio on\n" +
      "Mahalia singing before the dawn\n" +
      "Screen door keeping time like a tambourine\n\n" +
      "[Chorus]\n" +
      "That's front porch gospel, sweet and slow\n" +
      "The kind of sermon the biscuits know\n" +
      "Ain't no choir loft, just a porch swing pew\n" +
      "Front porch gospel, me and you\n\n" +
      "[Verse 2]\n" +
      "Sweet tea sweating in a mason jar\n" +
      "Heaven never felt so near, so far\n" +
      "Grace gets passed like a serving spoon",
    sunoUrl: "",
    audioUrl: "",
  },
];
