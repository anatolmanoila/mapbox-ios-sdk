//
//  RMTimeImageSet.m
//
// Copyright (c) 2008-2009, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "RMGlobalConstants.h"
#import "RMTileLoader.h"

#import "RMTileImage.h"
#import "RMTileSource.h"
#import "RMPixel.h"
#import "RMMercatorToScreenProjection.h"
#import "RMFractalTileProjection.h"
#import "RMTileImageSet.h"

#import "RMTileCache.h"

@implementation RMTileLoader

@synthesize loadedBounds, loadedZoom;

- (id)init
{
    if (!(self = [self initWithContent:nil]))
        return nil;

    return self;
}

- (id)initWithContent:(RMMapContents *)contents
{
    if (!(self = [super init]))
        return nil;

    mapContents = contents;

    [self clearLoadedBounds];
    loadedTiles.origin.tile = RMTileDummy();

    suppressLoading = NO;

    return self;
}

- (void)clearLoadedBounds
{
    loadedBounds = CGRectZero;
    [[mapContents imagesOnScreen] resetTiles];
}

- (BOOL)screenIsLoaded
{
    //	RMTileRect targetRect = [content tileBounds];
    BOOL contained = CGRectContainsRect(loadedBounds, [mapContents screenBounds]);

    NSUInteger targetZoom = (NSUInteger)([[mapContents mercatorToTileProjection] calculateNormalisedZoomFromScale:[mapContents scaledMetersPerPixel]]);
    if ((targetZoom > mapContents.maxZoom) || (targetZoom < mapContents.minZoom))
    {
        RMLog(@"target zoom %d is outside of RMMapContents limits %f to %f", targetZoom, mapContents.minZoom, mapContents.maxZoom);
    }

//    if (contained == NO)
//    {
//        RMLog(@"reassembling because its not contained");
//    }

//    if (targetZoom != loadedZoom)
//    {
//        RMLog(@"reassembling because target zoom = %f, loaded zoom = %d", targetZoom, loadedZoom);
//    }

    return contained && targetZoom == loadedZoom;
}

- (void)updateLoadedImages
{
    if (suppressLoading)
        return;

    if ([mapContents mercatorToTileProjection] == nil || [mapContents mercatorToScreenProjection] == nil)
        return;

    if ([self screenIsLoaded])
        return;

    RMTileRect newTileRect = [mapContents tileBounds];

    RMTileImageSet *images = [mapContents imagesOnScreen];
    images.zoom = newTileRect.origin.tile.zoom;

    CGRect newLoadedBounds = [images loadTiles:newTileRect toDisplayIn:[mapContents screenBounds]];

    if (!RMTileIsDummy(loadedTiles.origin.tile))
    {
        [images removeTilesOutsideOf:newTileRect];
    }

    loadedBounds = newLoadedBounds;
    loadedZoom = newTileRect.origin.tile.zoom;
    loadedTiles = newTileRect;

    [mapContents tilesUpdatedRegion:newLoadedBounds];
}

- (void)moveBy:(CGSize)delta
{
    loadedBounds = RMTranslateCGRectBy(loadedBounds, delta);
    [self updateLoadedImages];
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)center
{
    loadedBounds = RMScaleCGRectAboutPoint(loadedBounds, zoomFactor, center);
    [self updateLoadedImages];
}

- (BOOL)suppressLoading
{
    return suppressLoading;
}

- (void)setSuppressLoading:(BOOL)suppress
{
    suppressLoading = suppress;

    if (suppress == NO)
        [self updateLoadedImages];
}

- (void)reset
{
    loadedTiles.origin.tile = RMTileDummy();
}

- (void)reload
{
    [self clearLoadedBounds];
    [self updateLoadedImages];
}

@end
