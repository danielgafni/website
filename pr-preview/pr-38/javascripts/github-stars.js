// Star counts for the GitHub repositories on project cards. The theme's
// built-in source widget only supports the single site-wide `repo_url`.
// Counts are cached for a day to stay well within GitHub's anonymous API
// rate limit (60 requests per hour per visitor).
const TTL = 24 * 60 * 60 * 1000

document$.subscribe(() => {
  for (const el of document.querySelectorAll("[data-github-stars]")) {
    const repo = el.dataset.githubStars
    const key = `github-stars:${repo}`
    const show = (stars) => {
      el.lastElementChild.textContent = Number(stars).toLocaleString("en")
      el.hidden = false
    }
    const cached = JSON.parse(localStorage.getItem(key))
    if (cached && Date.now() - cached.time < TTL) {
      show(cached.stars)
      continue
    }
    fetch(`https://api.github.com/repos/${repo}`)
      .then((res) => (res.ok ? res.json() : Promise.reject(res.status)))
      .then(({ stargazers_count: stars }) => {
        localStorage.setItem(key, JSON.stringify({ stars, time: Date.now() }))
        show(stars)
      })
      .catch(() => cached && show(cached.stars))
  }
})
