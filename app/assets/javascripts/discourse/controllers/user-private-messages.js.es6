import computed from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({

  pmView: false,

  privateMessagesActive: Em.computed.equal('pmView', 'index'),
  privateMessagesMineActive: Em.computed.equal('pmView', 'mine'),
  privateMessagesUnreadActive: Em.computed.equal('pmView', 'unread'),
  isGroup: Em.computed.equal('pmView', 'groups'),


  @computed('model.private_messages_stats.groups', 'groupFilter', 'pmView')
  groupPMStats(stats,filter,pmView) {
    if (stats) {
      return stats.map(g => {
        return {
          name: g.name,
          count: g.count,
          active: (g.name === filter && pmView === 'groups')
        };
      });
    }
  }
});
