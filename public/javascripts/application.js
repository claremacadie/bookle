$(function() {
  $("form.reset_password").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    var ok = confirm("Are you sure you want to reset the password? This cannot be undone!");
    if (ok) {
      this.submit();
    }
  });
});

$(function() {
  $("form.delete_book").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    var ok = confirm("Are you sure you want to delete this book? This cannot be undone!");
    if (ok) {
      this.submit();
    }
  });
});

$(function() {
  $("form.delete_category").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    var ok = confirm("Are you sure you want to delete this category? This cannot be undone!");
    if (ok) {
      this.submit();
    }
  });
});

$(function() {
  $("form.signout").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    var ok = confirm("Are you sure you want to sign out?");
    if (ok) {
      this.submit();
    }
  });
});
