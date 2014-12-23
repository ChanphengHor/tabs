
@ReactiveTabs = ReactiveTabs = do ->

  createInterface = (options) ->

    check options, Match.ObjectIncluding
      template: String
      onChange: Match.Optional(Function)

    template = Template[options.template]

    if template

      events = {}

      events['click .tab-item'] = (e, t) ->
        t._activeTab.set(this)

      created = ->
        self = this
        check(self.data.tabs, Array)
        check(self.data.activeTab, Match.Optional(String))

        # Init--set first tab if no specified active tab
        if self.data.activeTab
          activeTab = {slug: self.data.activeTab}
        else
          activeTab = self.data.tabs[0]

        # Set up reactive data structures
        self._tabs = new ReactiveArray(self.data.tabs)
        self._activeTab = new Blaze.ReactiveVar(activeTab)

        # Set tabs--reactive
        self.setTabs = (array) ->
          if Match.test(array, Array)
            self._tabs.set(array)

        # Set active tab--takes a full tab object or a slug
        self.setActiveTab = (tab) ->
          if Match.test(tab, String)
            tab = {slug: tab}

            self._activeTab.set(tab)

        # See if a slug is the currently active one
        self.isActiveSlug = (slug) ->
          self._activeTab.get()?.slug is slug

      rendered = ->
        self = this
        contentBlocks = self.findAll('.tabs-content-container > div')
        renderCallbacks = {}

        self.autorun ->
          tabs = self._tabs.get()
          for tab, i in tabs

            # Register onRender callbacks by slug
            if tab.onRender?
              renderCallbacks[tab.slug] = tab.onRender

            # Add data-tab attribute to all tabbed content areas
            ($ contentBlocks[i]).addClass('tabs-content').attr('data-tab', tab.slug)

        # Sync corresponding content areas with active tab
        self.autorun ->
          activeTab = self._activeTab.get()
          slug = activeTab?.slug

          # Moved onChange to before render
          if options?.onChange?
            options.onChange(slug)

          ($ self.findAll('.tabs-content')).hide()
          ($ self.find("[data-tab='#{slug}']")).show()

          # Call render callback for this slug
          if renderCallbacks[slug]?.onRender?
            renderCallbacks[slug].onRender()

      helpers = {
        activeTab: (slug) ->
          if Template.instance().isActiveSlug(slug)
            return 'active'

        # Use these trackers if you want to reactively change tabs/activeTab from the outside
        trackActiveTab: (activeTab) ->
          Template.instance().setActiveTab(activeTab)

        trackTabs: (tabs) ->
          Template.instance().setTabs(tabs)
      }

      # Put it all together!
      template.created = created
      template.rendered = rendered
      template.helpers(helpers)
      template.events(events)

  return {
    createInterface: createInterface
  }
