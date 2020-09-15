---
authors: Jaime Gomes <jaime.gomes@suse.com>
state: discussion
discussion: https://github.com/cloudfoundry-incubator/kubecf/pull/1223
---

# Request for Discussion

The goal is to have an constructive discussion within the team about an idea and capture it in a
document known by RFD.

## Scope

## Metadata

1. authors: owners of the RFD must be listed with their name and email address
(John Doe <john.doe@wonder.land>).
2. state: one of the states discussed below.

## State

1. draft
2. discussion
3. published
4. abandoned

The ```draft``` state indicates that the work is not ready for discussion yet. It is a placeholder
for the RFD author(s) to put their thoughts into.
The RFD author(s) has to state the scope of the RFD as clearly and concise as possible before
promoting it to ```discussion```.

Documents under active discussion within the team must be in ```discussion``` state. When reaching
this state the scope of the RFD must be clear and well defined.

Once the discussion converges to a clear understanding of what needs to be done, then the state must
be set to ```published```.

Any comment in the ```published``` state must be raised as issues or if the comment brings
fundamental changes to the original content of the RFD then a new RFD must be created.

The ```abandoned``` state indicates that the RFD will not be implemented and it can be switched from
any previous state. Depending on the current RFD state, it may be the author(s) making an individual
decision (```draft```) or a collective decision (```discussion``` or ```published```).

Here is a diagram to illustrate the different RFD states:

```
+---------+           +--------------+            +---------------+
|         |           |              |            |               |
|  draft  +---------->+  discussion  +----------->+   published   |
|         |   PR      |              |    Merge   |               |
+---+-----+           +-----+--------+            +---------------+
    |                       |
    |                       | Merge
    |                       |
    |                       v
    |              +--------+-------+
    |              |                |
    +------------->+   abandoned    |
                   |                |
      PR + Merge   +----------------+
```

## Workflow

Some of these steps may have some script support in the future to make everyone's life easier.

### Find Next RFD Number

Check for the next RFD number by going through the RFDs table.

### Create a Branch & Placeholder

Create an RFD branch using the name after the last (i.e. 0009) known RFD number:

``` shell
# git checkout -b rfd-0010
```

and create the placeholder:

``` shell
# mkdir -p docs/rfd/0010
# touch docs/rfd/0010/README.md
```

Fill in the RFD authors and set the state to ```draft```.

### Push Branch Remotely

Push the changes to your RFD branch.

``` shell
# git add docs/rfd/0010/README.md
# git commit -m "rfd-0010: adding placeholder for RFD..."
# git push origin 0010
```

In the future, after the branch was pushed, the table in the README will be automatically updated to
reflect the new RFD or the change of state as well.

Now is time for you to fill the RFD with your thoughts to the point where you think it's good to
start sharing with others, to get their feedback and have a productive discussion.

### Open a Pull Request for Discussion

When ready to share with the team, then change the state from ```draft``` to ```discussion```
and push it remotely.

```shell
# git commit -m "rfd-0010: change RFD state to discussion"
# git push origin rfd-0010
```

Do not forget to open a pull request (maybe later we will have a bot for this) with the title
_RDF:num_ .

With the pull request open anyone subscribed to the repository will be notified about the new RFD
and it can gather feedback through pull request comments.

It's up to the author(s) to incorporate any pull request comment into the RFD.

### Merge the Pull Request

After a while, and with team members feedback, the author(s) would merge the pull request into the
master branch, but before that it must the state to ```published```. At this moment, the RFD must be
ready for implementation.

If an RFD state is switched to ```abandoned``` the pull request must be merged into the master
branch. If the RFD is in a ```draft``` state then a pull request must be opened and merged for future reference.
