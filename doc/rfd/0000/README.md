---
authors: Jaime Gomes <jaime.gomes@suse.com>
state: discussion
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
4. commited
5. abandoned

The ```draft``` state indicates that the work is not ready for discussion and that a placeholder
was set. The RFD owner is puting his thoughs in place before promoting to ```discussion```.

Documents under active discussion within the team should be in ```discussion``` state. When reaching
this state the scope of the RFD must be clear and well defined.

Once the discussion converges to an agreement then the state should be set to ```published```.

Once well defined, the state should be in ```commited``` state. Any comment in the ```commited```
state should be raised as issues or if the comment brings fundamental changes to the original
content of the RFD then a new RFD should be created.

Finally, if an idea will never be implemented or it should be ignored then it can be moved to the
```abandoned``` state at any time.

## Workflow

Some of these steps may have some script support in the future to make everyones life easier.

### Find Next RFD Number

Check for the next RFD number by going through the RFDs table.

### Create a Branch & Placeholder

Create a RFD branch using the name after the last (i.e. 0009) known RFD number:

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

In the future, after the branch pushed, the table in the README will be automatically updated to
reflect the new RFD or the change of state as well.

Now is time for you to fill the RFD with your thoughts to the point where you think it's good to
start sharing with others, to get their feedback and have a productive discussions.

### Open a Pull Request for Discussion

When ready to share with the team, then change the state from ```draft``` to ```discussion```
and push it remotely.

```shell
# git commit -m "rfd-0010: change RFD state to discussion"
# git push origin rfd-0010
```

Do not forget to open a pull request (maybe later we will have a bot for this) with the title
_RDF:num_ .

With the pull request open anyone register to the repository can read the RFD and give feedback
through pull request comments.

It's up to the author(s) to incorporate any pull request comment into the RFD.

### Merge the Pull Request

After a while, and with team members feedback, the author(s) would merge the pull request into the
master branch and change the state to ```published```.
The timeline is up to the author(s), but as guideline it could go from a 3-5 days to 2 weeks.

Before merging the pull request the state must also change to ```commited``` that indicates that the
RFD has involve from an idea to a clear description of a system or process and it can be
implemented.