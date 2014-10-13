export default Discourse.Route.extend({
   beforeModel: function(transition){
     // @Robin some ember magic needed here, I can't get this to work right
     var path = "/c/" + transition.params.categoryRedirect.catchAll;
     this.replaceWith(path);
   }
});
