import type { Config } from '@docusaurus/types'
import type * as Preset from '@docusaurus/preset-classic'

const websiteIcon = `
  <img class="navbar-social-link__icon-image navbar-social-link__icon-image--brand" src="/assets/antigma-logo.svg" alt="" />
`

const discordIcon = `
  <img class="navbar-social-link__icon-image navbar-social-link__icon-image--discord" src="/assets/discord-line.svg" alt="" />
`

const githubIcon = `
  <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
    <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"></path>
  </svg>
`

const socialLinkHtml = (label: string, icon: string) =>
  `<span class="navbar-social-link"><span class="navbar-social-link__icon">${icon}</span><span>${label}</span></span>`

const config: Config = {
  title: 'Ante',
  tagline: 'ai-native, cloud-native, local-first agent runtime',
  favicon: 'assets/ante2.png',
  url: 'https://ante.run',
  baseUrl: '/',

  markdown: {
    mermaid: true,
  },
  themes: [
    '@docusaurus/theme-mermaid',
    [
      require.resolve('@easyops-cn/docusaurus-search-local'),
      {
        hashed: true,
        indexDocs: true,
        docsRouteBasePath: '/',
        language: ['en'],
        highlightSearchTermsOnTargetPage: true,
        explicitSearchResultPath: true,
      },
    ],
  ],

  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    navbar: {
      title: 'Ante',
      logo: {
        alt: 'Ante',
        src: 'assets/ante.png',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'antix',
          position: 'left',
          label: 'Antix',
        },
        {
          href: 'https://antigma.ai',
          html: socialLinkHtml('Home', websiteIcon),
          position: 'right',
        },
        {
          href: 'https://discord.gg/pqhj3DNGz2',
          html: socialLinkHtml('Discord', discordIcon),
          position: 'right',
        },
        {
          href: 'https://github.com/AntigmaLabs/ante-preview',
          html: socialLinkHtml('GitHub', githubIcon),
          position: 'right',
        },
      ],
    },
    prism: {
      additionalLanguages: ['bash', 'json', 'rust', 'toml'],
    },
    colorMode: {
      defaultMode: 'light',
      respectPrefersColorScheme: true,
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            { label: 'Overview', to: '/' },
            { label: 'Quickstart', to: '/start/quickstart' },
            { label: 'Configuration', to: '/configuration/providers' },
          ],
        },
        {
          title: 'Community',
          items: [
            { label: 'Discord', href: 'https://discord.gg/pqhj3DNGz2' },
            { label: 'GitHub', href: 'https://github.com/AntigmaLabs/ante-preview' },
          ],
        },
        {
          title: 'Company',
          items: [
            { label: 'Home', href: 'https://antigma.ai' },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Antigma Labs`,
    },
  } satisfies Preset.ThemeConfig,
}

export default config
